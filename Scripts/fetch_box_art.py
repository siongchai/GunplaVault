#!/usr/bin/env python3
"""Fetch Gunpla box art URLs from Gunpla Wiki (Fandom) into seed_kits.json."""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.parse
import urllib.request
from difflib import SequenceMatcher
from pathlib import Path

WIKI_API = "https://gunpla.fandom.com/api.php"
USER_AGENT = "GunplaVault/1.0 (seed box art enrichment; personal project)"
RATE_LIMIT_SEC = 0.35

INFobox_IMAGE = re.compile(r"\|\s*image\s*=\s*(.+)", re.IGNORECASE)
GALLERY_BOX = re.compile(r"([\w\s\-()]+box(?:art|Art)[\w\s\-().]*\.(?:jpg|jpeg|png))", re.IGNORECASE)
REDIRECT = re.compile(r"#redirect\s*\[\[([^|\]]+)", re.IGNORECASE)


def api_get(params: dict) -> dict:
    query = urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(f"{WIKI_API}?{query}", headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def search_page_title(name: str, grade: str) -> str | None:
    """Find the best matching wiki page title for a seed kit."""
    queries = build_search_queries(name, grade)
    best_title: str | None = None
    best_score = 0.0

    for query in queries:
        data = api_get(
            {
                "action": "query",
                "list": "search",
                "srsearch": query,
                "srlimit": 8,
            }
        )
        time.sleep(RATE_LIMIT_SEC)

        for hit in data.get("query", {}).get("search", []):
            title = hit["title"]
            score = title_score(title, name, grade)
            if score > best_score:
                best_score = score
                best_title = title

        if best_score >= 0.72:
            break

    return best_title if best_score >= 0.45 else None


def build_search_queries(name: str, grade: str) -> list[str]:
    base = name.strip()
    if base.startswith("[P-Bandai]"):
        base = base.replace("[P-Bandai]", "", 1).strip()

    variants = [base]
    for suffix in (" Ver.Ka", " HWS", " Full Armor", " EW", " Revive", " Titanium Finish", " Clear Color", " (Reissue)", " Coating"):
        if base.endswith(suffix):
            variants.append(base[: -len(suffix)].strip())

    grade_prefix = grade if grade != "Other" else "HG"
    queries: list[str] = []
    for variant in variants[:2]:
        queries.append(f"{grade_prefix} {variant}")
        if "Gundam" not in variant and "Zaku" not in variant and "GM" not in variant:
            queries.append(f"{grade_prefix} {variant} Gundam")
    return queries


def title_score(title: str, name: str, grade: str) -> float:
    title_l = title.lower()
    name_l = name.lower().replace("[p-bandai]", "").strip()
    grade_l = grade.lower()

    if "master grade" in title_l and grade_l != "mg":
        return 0.0
    if "real grade" in title_l and grade_l != "rg":
        return 0.0
    if title_l.startswith("hg") and grade_l not in ("hg", "other"):
        if grade_l in ("mg", "rg", "pg", "mgex"):
            return 0.0

    grade_tokens = {
        "hg": ["hg ", "high grade", "hguc", "hgbf", "hgce", "hgibo", "hgfc", "hggg", "hggu", "hggto"],
        "rg": ["rg ", "real grade"],
        "mg": ["mg ", "master grade"],
        "mgex": ["mgex", "master grade extreme"],
        "pg": ["pg ", "perfect grade"],
        "sd": ["sd ", "sdbb", "sdex", "sdcb"],
        "p-bandai": ["p-bandai", "[p-bandai]"],
    }
    tokens = grade_tokens.get(grade_l, [grade_l])
    grade_match = any(tok in title_l for tok in tokens)

    ratio = SequenceMatcher(None, title_l, name_l).ratio()
    keyword_bonus = sum(0.08 for word in name_l.split() if len(word) > 3 and word in title_l)
    score = ratio + keyword_bonus
    if grade_match:
        score += 0.25
    if "box" in title_l:
        score -= 0.2
    return score


def fetch_wikitext(title: str, depth: int = 0) -> str | None:
    if depth > 2:
        return None
    data = api_get(
        {
            "action": "query",
            "prop": "revisions",
            "rvprop": "content",
            "rvslots": "main",
            "titles": title,
        }
    )
    time.sleep(RATE_LIMIT_SEC)

    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        if "missing" in page:
            return None
        content = page["revisions"][0]["slots"]["main"]["*"]
        redirect = REDIRECT.search(content)
        if redirect:
            return fetch_wikitext(redirect.group(1).strip(), depth + 1)
        return content
    return None


def extract_box_filename(wikitext: str) -> str | None:
    match = INFobox_IMAGE.search(wikitext)
    if match:
        filename = match.group(1).strip()
        filename = filename.split("|")[0].strip()
        if filename.lower().startswith("file:"):
            filename = filename[5:].strip()
        if filename and not filename.startswith("#"):
            return filename

    gallery_match = GALLERY_BOX.search(wikitext)
    if gallery_match:
        return gallery_match.group(1).strip()

    return None


def resolve_image_url(filename: str) -> str | None:
    title = filename if filename.lower().startswith("file:") else f"File:{filename}"
    data = api_get(
        {
            "action": "query",
            "titles": title,
            "prop": "imageinfo",
            "iiprop": "url",
        }
    )
    time.sleep(RATE_LIMIT_SEC)

    for page in data.get("query", {}).get("pages", {}).values():
        info = page.get("imageinfo")
        if info:
            return info[0].get("url")
    return None


def fetch_box_art_for_kit(kit: dict) -> str | None:
    title = search_page_title(kit["name"], kit["grade"])
    if not title:
        return None

    wikitext = fetch_wikitext(title)
    if not wikitext:
        return None

    filename = extract_box_filename(wikitext)
    if not filename:
        return None

    return resolve_image_url(filename)


def load_seed_database(path: Path) -> dict:
    with path.open() as f:
        return json.load(f)


def save_seed_database(path: Path, data: dict) -> None:
    with path.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Enrich seed_kits.json with boxArtUrl from Gunpla Wiki")
    parser.add_argument("--limit", type=int, default=0, help="Max kits to process (0 = all missing)")
    parser.add_argument("--force", action="store_true", help="Re-fetch even if boxArtUrl exists")
    parser.add_argument(
        "--seed-path",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "GunplaVault/Resources/SeedData/seed_kits.json",
    )
    args = parser.parse_args()

    data = load_seed_database(args.seed_path)
    kits: list[dict] = data.get("kits", [])

    processed = 0
    found = 0
    skipped = 0
    failed = 0

    for kit in kits:
        if kit.get("boxArtUrl") and not args.force:
            skipped += 1
            continue
        if args.limit and processed >= args.limit:
            break

        processed += 1
        label = f"{kit['grade']} {kit['name']}"
        print(f"[{processed}] {label}...", flush=True)

        try:
            url = fetch_box_art_for_kit(kit)
        except Exception as exc:  # noqa: BLE001
            print(f"  ! error: {exc}")
            failed += 1
            continue

        if url:
            kit["boxArtUrl"] = url
            found += 1
            print(f"  ✓ {url[:80]}...")
        else:
            kit["boxArtUrl"] = None
            failed += 1
            print("  ✗ not found")

        if processed % 10 == 0:
            data["kits"] = kits
            save_seed_database(args.seed_path, data)

    data["kits"] = kits
    from datetime import date

    data["updatedAt"] = str(date.today())
    save_seed_database(args.seed_path, data)

    total_with_art = sum(1 for k in kits if k.get("boxArtUrl"))
    print(
        f"\nDone. processed={processed} found={found} skipped={skipped} failed={failed} "
        f"total_with_art={total_with_art}/{len(kits)}"
    )


if __name__ == "__main__":
    main()
