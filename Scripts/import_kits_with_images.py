#!/usr/bin/env python3
"""Import Gunpla kits with box art into seed_kits.json.

Primary source: gunpla.fandom.com MediaWiki API (box art via Wikia CDN).
Secondary: optional gunpladb.net JSON dump (from WebFetch scrapes) and HLJ.
"""

from __future__ import annotations

import hashlib
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

UA = "GunplaVaultBot/1.0 (GunplaVault catalog enrichment; https://github.com/)"
WIKI_API = "https://gunpla.fandom.com/api.php"
ROOT = Path(__file__).resolve().parents[1]
SEED_PATH = ROOT / "GunplaVault/Resources/SeedData/seed_kits.json"
GUNPLADB_DUMP = ROOT / "Scripts/data/gunpladb_pages.json"
OUT_PATH = SEED_PATH

# Prefer grade line categories (dedupe by pageid across them).
CATEGORIES = [
    ("HG", "HG"),
    ("Real Grade", "RG"),
    ("Master Grade", "MG"),
    ("Master Grade Extreme", "MGEX"),
    ("Perfect Grade", "PG"),
    ("SD Gundam BB Senshi", "SD"),
    ("SD Gundam Cross Silhouette", "SD"),
    ("SD Gundam EX-Standard", "SD"),
    ("Entry Grade", "Other"),
    ("Full Mechanics", "Other"),
]

VALID_GRADES = {"HG", "RG", "MG", "MGEX", "PG", "SD", "P-Bandai", "Other"}

SCALE_BY_GRADE = {
    "HG": "1/144",
    "RG": "1/144",
    "MG": "1/100",
    "MGEX": "1/100",
    "PG": "1/60",
    "SD": "SD",
    "P-Bandai": "1/144",
    "Other": "1/144",
}

GUNDAM_HINTS = re.compile(
    r"gundam|gunpla|mobile suit|zaku|gelgoog|dom|gouf|gm |jegan|unicorn|"
    r"freedom|justice|strike|exia|00 |wing |seed|witch|ibar|orphan|barbato|"
    r"aerial|nu gundam|ν |hi-ν|sazabi|zeta|ζ|qubeley|astray|destiny|"
    r"ib o|uc |universal century|after colony|cosmic era|anno domini|"
    r"post disaster|asw-g|xvx-|gat-|zgmf-|gn-|xxxg-|rx-|ms-|rgm-|msn-",
    re.I,
)

SKIP_TITLE = re.compile(
    r"\b(mazinger|grendizer|getter|macross|ultraman|evangelion|code geass|"
    r"patlabor|sakura wars|sakura taisen|dragonball|one piece|naruto|"
    r"category:|list of|template:)\b",
    re.I,
)

YEAR_RE = re.compile(r"(19|20)\d{2}")
MONTH_YEAR_RE = re.compile(
    r"(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2},?\s*)?((19|20)\d{2})",
    re.I,
)


def api(params: dict) -> dict:
    params = {**params, "format": "json"}
    query = urllib.parse.urlencode(params)
    req = urllib.request.Request(
        f"{WIKI_API}?{query}",
        headers={"User-Agent": UA, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        return json.loads(resp.read().decode())


def api_retry(params: dict, tries: int = 4) -> dict:
    last = None
    for i in range(tries):
        try:
            return api(params)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            last = exc
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"API failed after retries: {last}")


def clean_wiki_text(value: str | None) -> str:
    if not value:
        return ""
    text = value
    text = re.sub(r"\{\{[^}]*\}\}", " ", text)
    text = re.sub(r"\[\[([^|\]]+)\|([^\]]+)\]\]", r"\2", text)
    text = re.sub(r"\[\[([^\]]+)\]\]", r"\1", text)
    text = re.sub(r"<br\s*/?>", " ", text, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"'{2,}", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_infobox(wikitext: str) -> dict[str, str]:
    match = re.search(
        r"\{\{\s*Plamo Infobox\s*(.*?)\}\}",
        wikitext,
        flags=re.I | re.S,
    )
    if not match:
        # Some pages use slightly different casing / spacing
        match = re.search(r"\{\{\s*Plamo[_\s]?Infobox\s*(.*?)\}\}", wikitext, flags=re.I | re.S)
    if not match:
        return {}
    block = match.group(1)
    fields: dict[str, str] = {}
    for fm in re.finditer(r"\|\s*([A-Za-z0-9 /_-]+?)\s*=\s*([^\n|{]+)", block):
        key = fm.group(1).strip().lower()
        val = fm.group(2).strip()
        if key and val:
            fields[key] = val
    return fields


def parse_year(release: str | None, title: str) -> int:
    if release:
        m = MONTH_YEAR_RE.search(release)
        if m:
            return int(m.group(3))
        years = YEAR_RE.findall(release)
        # findall with groups returns tuples for (19|20) — fix
        years = re.findall(r"((?:19|20)\d{2})", release)
        if years:
            return int(years[0])
    m = re.search(r"\(((?:19|20)\d{2})\)", title)
    if m:
        return int(m.group(1))
    return 2000


def detect_grade(title: str, default: str, fields: dict[str, str], categories: list[str]) -> str:
    blob = " ".join([title, fields.get("classification", ""), " ".join(categories)]).lower()
    if "p-bandai" in blob or "premium bandai" in blob or title.lower().startswith("[p-bandai]"):
        return "P-Bandai"
    if "mgex" in blob or "master grade extreme" in blob:
        return "MGEX"
    if re.search(r"\brg\b|real grade", blob):
        return "RG"
    if re.search(r"\bpg\b|perfect grade", blob):
        return "PG"
    if re.search(r"\bmg\b|master grade|mgsd", blob) and "mgex" not in blob:
        if "mgsd" in blob:
            return "SD"
        return "MG"
    if re.search(r"\bsd\b|bb senshi|cross silhouette|ex-standard|ex standard", blob):
        return "SD"
    if re.search(r"\bhg\b|high grade|hguc|hgce|hgbf|hgbd|hgib|hgac|hgfc", blob):
        return "HG"
    return default if default in VALID_GRADES else "Other"


def detect_scale(grade: str, fields: dict[str, str]) -> str:
    scale = clean_wiki_text(fields.get("scale", ""))
    if scale:
        # Normalize common forms
        if re.search(r"1\s*[:/]\s*144", scale):
            return "1/144"
        if re.search(r"1\s*[:/]\s*100", scale):
            return "1/100"
        if re.search(r"1\s*[:/]\s*60", scale):
            return "1/60"
        if "sd" in scale.lower():
            return "SD"
        return scale[:32]
    return SCALE_BY_GRADE.get(grade, "1/144")


def detect_series(fields: dict[str, str], categories: list[str], title: str) -> str:
    franchise = clean_wiki_text(fields.get("franchise", ""))
    if franchise:
        # Take first franchise if multiple
        franchise = re.split(r"[;/,]", franchise)[0].strip()
        if franchise:
            return franchise[:80]
    for cat in categories:
        name = cat.replace("Category:", "")
        if name.startswith("Mobile Suit") or name.startswith("Gundam") or name.startswith("The Witch"):
            return name[:80]
        if name in {
            "Iron-Blooded Orphans",
            "Char's Counterattack",
            "Zeta Gundam",
            "ZZ Gundam",
            "Gundam Wing",
            "Gundam SEED",
            "Gundam SEED DESTINY",
            "Gundam 00",
            "GQuuuuuuX",
        }:
            return name
    # Infer from title prefixes
    if title.upper().startswith("HGUC") or "UC" in title:
        return "Mobile Suit Gundam"
    return "Gundam"


def clean_kit_name(title: str, grade: str) -> str:
    name = title.strip()
    # Drop redundant year suffix for display when present as trailing (YYYY)
    # Keep distinctive variant markers.
    prefixes = [
        "HGUC ", "HGCE ", "HGBF ", "HGBD ", "HGBD:R ", "HGIBO ", "HGAC ", "HGFC ",
        "HGGBM ", "HGGTO ", "HGAGE ", "HGAC ", "HG ", "RG ", "MGEX ", "MG ", "PG ",
        "EG ", "FM ", "RE/100 ", "SDCS ", "SDEX ", "BB Senshi ", "BB ",
    ]
    upper = name
    for p in prefixes:
        if upper.lower().startswith(p.lower()):
            name = name[len(p) :].strip()
            break
    return name[:120] or title[:120]


def kit_id_from_page(page_id: int) -> str:
    return f"seed-wiki-{page_id}"


def is_gundam_related(title: str, fields: dict[str, str], categories: list[str]) -> bool:
    if SKIP_TITLE.search(title):
        return False
    blob = " ".join(
        [
            title,
            fields.get("franchise", ""),
            fields.get("classification", ""),
            fields.get("model of", ""),
            " ".join(categories),
        ]
    )
    return bool(GUNDAM_HINTS.search(blob))


def first_paragraph(wikitext: str) -> str | None:
    # Drop templates / headings, take first prose sentence block
    text = re.sub(r"\{\{[^{}]*\}\}", " ", wikitext)
    # crude nested template strip
    for _ in range(3):
        text = re.sub(r"\{\{[^{}]*\}\}", " ", text)
    text = re.sub(r" bro}", " ", text)
    text = re.sub(r"^=+.*?=+\s*", "", text, flags=re.M)
    text = re.sub(r"\[\[([^|\]]+)\|([^\]]+)\]\]", r"\2", text)
    text = re.sub(r"\[\[([^\]]+)\]\]", r"\1", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"'{2,}", "", text)
    paras = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    for p in paras:
        if p.startswith("|") or p.startswith("{") or p.startswith("!") or len(p) < 40:
            continue
        if p.startswith("Category") or p.startswith("File:"):
            continue
        cleaned = re.sub(r"\s+", " ", p).strip()
        if len(cleaned) > 40:
            return cleaned[:280]
    return None


def iter_category_pages(category: str):
    cont = None
    while True:
        params = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": f"Category:{category}",
            "cmnamespace": "0",
            "cmlimit": "500",
        }
        if cont:
            params["cmcontinue"] = cont
        data = api_retry(params)
        for m in data.get("query", {}).get("categorymembers", []):
            yield m
        cont = (data.get("continue") or {}).get("cmcontinue")
        if not cont:
            break
        time.sleep(0.15)


def fetch_page_batch(titles: list[str]) -> list[dict]:
    """Fetch pageimages + revisions + categories for up to ~20 titles."""
    if not titles:
        return []
    data = api_retry(
        {
            "action": "query",
            "titles": "|".join(titles),
            "prop": "pageimages|categories|revisions|info",
            "piprop": "original",
            "rvprop": "content",
            "rvslots": "main",
            "cllimit": "50",
            "inprop": "url",
        }
    )
    pages = data.get("query", {}).get("pages", {})
    return list(pages.values())


def page_to_kit(page: dict, default_grade: str) -> dict | None:
    if page.get("missing") is not None or "title" not in page:
        return None
    title = page["title"]
    page_id = page.get("pageid")
    if not page_id:
        return None
    if ":" in title and not title.lower().startswith(("hg", "rg", "mg", "pg", "sd", "eg", "fm", "bb", "re")):
        # Skip weird namespace-like titles
        if title.split(":", 1)[0] in {"File", "Category", "Template", "User", "Talk"}:
            return None

    revs = page.get("revisions") or []
    wikitext = ""
    if revs:
        slot = revs[0].get("slots", {}).get("main", {})
        wikitext = slot.get("*") or revs[0].get("*") or ""

    fields = parse_infobox(wikitext)
    cats = [c.get("title", "") for c in page.get("categories", [])]
    if not is_gundam_related(title, fields, cats):
        return None

    img = (page.get("original") or {}).get("source")
    # Prefer box-art-looking filename from infobox when page image missing
    if not img and fields.get("image"):
        fname = clean_wiki_text(fields["image"]).replace(" ", "_")
        if fname and not fname.lower().startswith("http"):
            # Resolve via imageinfo
            try:
                info = api_retry(
                    {
                        "action": "query",
                        "titles": f"File:{fname}",
                        "prop": "imageinfo",
                        "iiprop": "url",
                    }
                )
                for p in info.get("query", {}).get("pages", {}).values():
                    ii = (p.get("imageinfo") or [{}])[0]
                    img = ii.get("url")
            except Exception:
                img = None

    grade = detect_grade(title, default_grade, fields, cats)
    scale = detect_scale(grade, fields)
    series = detect_series(fields, cats, title)
    release_year = parse_year(fields.get("release date"), title)
    name = clean_kit_name(title, grade)
    jan = clean_wiki_text(fields.get("jan/isbn") or fields.get("jan") or "") or None
    if jan == "":
        jan = None
    model_of = clean_wiki_text(fields.get("model of") or "")
    lineup = clean_wiki_text(fields.get("lineup no.") or fields.get("lineup no") or "")
    classification = clean_wiki_text(fields.get("classification") or "")

    model_number = None
    if classification and lineup:
        # e.g. HGUC + 021
        short = classification.split(";")[0].strip()
        # Compress common names
        short = (
            short.replace("High Grade Universal Century", "HGUC")
            .replace("High Grade Cosmic Era", "HGCE")
            .replace("Real Grade", "RG")
            .replace("Master Grade Extreme", "MGEX")
            .replace("Master Grade", "MG")
            .replace("Perfect Grade", "PG")
            .replace("High Grade", "HG")
        )
        model_number = f"{short} {lineup}".strip()[:80]
    elif classification:
        model_number = f"{classification.split(';')[0].strip()} {name}"[:80]
    else:
        model_number = f"{grade} {name}"[:80]

    description = first_paragraph(wikitext)
    tags = []
    if series:
        tags.append(series.split()[0][:24])
    if "Ver.Ka" in title or "Ver. Ka" in title:
        tags.append("Ver.Ka")
    if "P-Bandai" in title or grade == "P-Bandai":
        tags.append("P-Bandai")
    if "Clear" in title:
        tags.append("Clear")
    if img:
        tags.append("BoxArt")

    return {
        "id": kit_id_from_page(page_id),
        "name": name,
        "series": series,
        "grade": grade,
        "scale": scale,
        "releaseYear": release_year,
        "partCount": None,
        "modelNumber": model_number,
        "barcode": jan,
        "boxArtUrl": img,
        "description": description,
        "isBandai": True,
        "tags": tags[:6],
        "_source": "gunpla.fandom.com",
        "_wikiTitle": title,
        "_modelOf": model_of or None,
    }


def import_from_wiki(max_kits: int | None = None) -> list[dict]:
    # Map pageid -> default grade from first category that lists it
    page_meta: dict[int, tuple[str, str]] = {}
    for cat, grade in CATEGORIES:
        print(f"Listing Category:{cat} …")
        for m in iter_category_pages(cat):
            pid = m.get("pageid")
            title = m.get("title")
            if not pid or not title:
                continue
            if pid not in page_meta:
                page_meta[pid] = (title, grade)
        time.sleep(0.2)

    print(f"Unique wiki pages listed: {len(page_meta)}")
    titles = [(pid, title, grade) for pid, (title, grade) in page_meta.items()]
    titles.sort(key=lambda t: t[0])

    kits: list[dict] = []
    seen_ids: set[str] = set()
    batch_size = 15
    for i in range(0, len(titles), batch_size):
        chunk = titles[i : i + batch_size]
        title_list = [t[1] for t in chunk]
        grade_by_title = {t[1]: t[2] for t in chunk}
        try:
            pages = fetch_page_batch(title_list)
        except Exception as exc:
            print(f"Batch failed at {i}: {exc}")
            time.sleep(2)
            continue
        for page in pages:
            kit = page_to_kit(page, grade_by_title.get(page.get("title", ""), "HG"))
            if not kit:
                continue
            if kit["id"] in seen_ids:
                continue
            # Prefer kits that have box art, but keep some without if under quota
            seen_ids.add(kit["id"])
            kits.append(kit)
            if max_kits and len(kits) >= max_kits:
                return kits
        if (i // batch_size) % 10 == 0:
            with_art = sum(1 for k in kits if k.get("boxArtUrl"))
            print(f"  progress {i + len(chunk)}/{len(titles)} → {len(kits)} kits ({with_art} with art)")
        time.sleep(0.25)
    return kits


def load_gunpladb_dump() -> list[dict]:
    if not GUNPLADB_DUMP.exists():
        return []
    data = json.loads(GUNPLADB_DUMP.read_text())
    return data if isinstance(data, list) else data.get("kits", [])


def gunpladb_to_kit(entry: dict) -> dict | None:
    name = (entry.get("name") or "").strip()
    grade_raw = (entry.get("grade") or "HG").strip()
    if not name:
        return None
    grade_map = {
        "HG": "HG",
        "RG": "RG",
        "MG": "MG",
        "MGEX": "MGEX",
        "PG": "PG",
        "SD": "SD",
        "MGSD": "SD",
        "EG": "Other",
        "FM": "Other",
        "RE/100": "Other",
        "P-Bandai": "P-Bandai",
    }
    grade = grade_map.get(grade_raw, "Other")
    if entry.get("pBandai") or "p-bandai" in (entry.get("description") or "").lower():
        grade = "P-Bandai"
    release = entry.get("release") or entry.get("releaseDate") or ""
    year = parse_year(str(release), name)
    series = entry.get("series") or "Gundam"
    desc = entry.get("description")
    box = entry.get("boxArtUrl") or entry.get("image")
    raw = f"gunpladb|{grade}|{name}|{year}"
    kid = "seed-gdb-" + hashlib.md5(raw.encode()).hexdigest()[:10]
    return {
        "id": kid,
        "name": name[:120],
        "series": series[:80],
        "grade": grade,
        "scale": SCALE_BY_GRADE.get(grade, "1/144"),
        "releaseYear": year,
        "partCount": entry.get("partCount"),
        "modelNumber": entry.get("modelNumber") or f"{grade} {name}"[:80],
        "barcode": entry.get("barcode"),
        "boxArtUrl": box,
        "description": (desc[:280] if desc else None),
        "isBandai": True,
        "tags": ["GunplaDB"] + (["BoxArt"] if box else []),
        "_source": "gunpladb.net",
    }


def normalize_name(name: str) -> str:
    n = name.lower()
    n = re.sub(r"\[p-bandai\]\s*", "", n)
    n = re.sub(r"[^a-z0-9]+", " ", n)
    return re.sub(r"\s+", " ", n).strip()


def merge_kits(wiki: list[dict], gdb: list[dict], curated: list[dict]) -> list[dict]:
    by_norm: dict[str, dict] = {}
    result: list[dict] = []

    def add(kit: dict, prefer_new_art: bool = True):
        public = {k: v for k, v in kit.items() if not k.startswith("_")}
        key = normalize_name(public["name"]) + "|" + public["grade"]
        existing = by_norm.get(key)
        if existing:
            # Enrich missing fields
            if prefer_new_art and public.get("boxArtUrl") and not existing.get("boxArtUrl"):
                existing["boxArtUrl"] = public["boxArtUrl"]
            if not existing.get("description") and public.get("description"):
                existing["description"] = public["description"]
            if not existing.get("barcode") and public.get("barcode"):
                existing["barcode"] = public["barcode"]
            if existing.get("series") in {"Gundam", ""} and public.get("series"):
                existing["series"] = public["series"]
            return
        by_norm[key] = public
        result.append(public)

    for k in curated:
        add(k)
    # Prefer wiki kits with images first
    wiki_sorted = sorted(wiki, key=lambda k: (0 if k.get("boxArtUrl") else 1, k.get("name", "")))
    for k in wiki_sorted:
        add(k)
    for entry in gdb:
        kit = gunpladb_to_kit(entry)
        if kit:
            add(kit)
    return result


def load_curated(existing_path: Path) -> list[dict]:
    if not existing_path.exists():
        return []
    data = json.loads(existing_path.read_text())
    curated = []
    for k in data.get("kits", []):
        if str(k.get("id", "")).startswith("seed-00") or str(k.get("id", "")).startswith("seed-0"):
            # keep first 10 curated style ids
            if re.match(r"seed-\d{3}$", k["id"]):
                curated.append(k)
    return curated[:10]


def enrich_curated_with_wiki_art(curated: list[dict], wiki: list[dict]) -> list[dict]:
    wiki_by_norm = {normalize_name(k["name"]): k for k in wiki if k.get("boxArtUrl")}
    out = []
    for k in curated:
        c = dict(k)
        key = normalize_name(c["name"])
        # fuzzy-ish: try exact, then substring
        match = wiki_by_norm.get(key)
        if not match:
            for wn, wk in wiki_by_norm.items():
                if key in wn or wn in key:
                    match = wk
                    break
        if match and match.get("boxArtUrl"):
            c["boxArtUrl"] = match["boxArtUrl"]
            if not c.get("barcode") and match.get("barcode"):
                c["barcode"] = match["barcode"]
            if not c.get("description") and match.get("description"):
                c["description"] = match["description"]
        out.append(c)
    return out


def strip_internal(kits: list[dict]) -> list[dict]:
    cleaned = []
    for k in kits:
        item = {key: val for key, val in k.items() if not key.startswith("_")}
        # Ensure grade validity
        if item.get("grade") not in VALID_GRADES:
            item["grade"] = "Other"
        cleaned.append(item)
    return cleaned


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--max", type=int, default=None, help="Max wiki kits to fetch (debug)")
    parser.add_argument("--skip-wiki", action="store_true")
    parser.add_argument("--prefer-with-art", action="store_true", default=True)
    args = parser.parse_args()

    curated = load_curated(SEED_PATH)
    wiki: list[dict] = []
    if not args.skip_wiki:
        wiki = import_from_wiki(max_kits=args.max)
        print(f"Wiki kits parsed: {len(wiki)} (with art: {sum(1 for k in wiki if k.get('boxArtUrl'))})")
        curated = enrich_curated_with_wiki_art(curated, wiki)

    gdb = load_gunpladb_dump()
    print(f"GunplaDB dump entries: {len(gdb)}")

    merged = merge_kits(wiki, gdb, curated)
    if args.prefer_with_art:
        # Keep all curated + all with art + fill remainder without art up to a soft cap
        with_art = [k for k in merged if k.get("boxArtUrl") or re.match(r"seed-\d{3}$", k.get("id", ""))]
        without = [k for k in merged if k not in with_art]
        # Prefer recent years for kits without art
        without.sort(key=lambda k: k.get("releaseYear", 0), reverse=True)
        # Cap total around 1200 to keep JSON reasonable, prioritizing art
        merged = with_art + without[: max(0, 1200 - len(with_art))]

    merged = strip_internal(merged)
    # Stable-ish order: curated first, then by year desc, name
    def sort_key(k):
        curated_rank = 0 if re.match(r"seed-\d{3}$", k.get("id", "")) else 1
        return (curated_rank, -int(k.get("releaseYear") or 0), k.get("name", ""))

    merged.sort(key=sort_key)

    payload = {
        "version": 2,
        "updatedAt": date.today().isoformat(),
        "kits": merged,
        "sources": [
            "gunpla.fandom.com (MediaWiki API)",
            "gunpladb.net (supplemental metadata)",
        ],
    }
    # SeedDatabase in Swift only decodes version/updatedAt/kits — extra key is ok if we strip it
    # Actually Codable ignores unknown keys by default? In Swift, decoding ignores unknown keys only if using custom decoder...
    # Foundation JSONDecoder ignores unknown keys by default? Actually NO - by default Swift Codable ignores unknown keys. Yes, JSONDecoder ignores extra keys.
    OUT_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    with_art = sum(1 for k in merged if k.get("boxArtUrl"))
    print(f"Wrote {len(merged)} kits ({with_art} with boxArtUrl) → {OUT_PATH}")


if __name__ == "__main__":
    main()
