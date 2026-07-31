#!/usr/bin/env python3
"""Merge HLJ + GunplaDB supplemental kits into an existing seed_kits.json."""

from __future__ import annotations

import hashlib
import json
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "GunplaVault/Resources/SeedData/seed_kits.json"
HLJ = ROOT / "Scripts/data/hlj_kits.json"
GDB = ROOT / "Scripts/data/gunpladb_pages.json"

VALID = {"HG", "RG", "MG", "MGEX", "PG", "SD", "P-Bandai", "Other"}
SCALE = {
    "HG": "1/144",
    "RG": "1/144",
    "MG": "1/100",
    "MGEX": "1/100",
    "PG": "1/60",
    "SD": "SD",
    "P-Bandai": "1/144",
    "Other": "1/144",
}


def norm(name: str) -> str:
    n = name.lower()
    n = re.sub(r"\[p-bandai\]\s*", "", n)
    n = re.sub(r"^(1/144|1/100|1/60)\s*", "", n)
    n = re.sub(r"^(hguc|hgce|hgb[df]|hgibo|hgac|hgfc|hg|rg|mgex|mg|pg|eg|sdcs|sdex|sd)\s+", "", n)
    n = re.sub(r"[^a-z0-9]+", " ", n)
    return re.sub(r"\s+", " ", n).strip()


def clean_hlj_name(name: str) -> str:
    n = re.sub(r"^(1/144|1/100|1/60)\s*", "", name).strip()
    n = re.sub(
        r"^(HGUC|HGCE|HGBF|HGBD|HGIBO|HGAC|HGFC|HG|RG|MGEX|MG|PG|EG|SDCS|SDEX|SD)\s+",
        "",
        n,
        flags=re.I,
    )
    return n.strip()[:120] or name[:120]


def main():
    seed = json.loads(SEED.read_text())
    kits = seed["kits"]
    by_key = {}
    for k in kits:
        by_key[norm(k["name"]) + "|" + k["grade"]] = k
        by_key.setdefault(norm(k["name"]), k)

    hlj = json.loads(HLJ.read_text()) if HLJ.exists() else []
    gdb = []
    if GDB.exists():
        raw = json.loads(GDB.read_text())
        gdb = raw if isinstance(raw, list) else raw.get("kits", [])

    added = 0
    enriched = 0

    for h in hlj:
        grade = h.get("grade") if h.get("grade") in VALID else "Other"
        name = clean_hlj_name(h["name"])
        key = norm(name) + "|" + grade
        art = h.get("boxArtUrl")
        if key in by_key:
            if art and not by_key[key].get("boxArtUrl"):
                by_key[key]["boxArtUrl"] = art
                enriched += 1
            continue
        # Try name-only match across grades for art enrichment
        nkey = norm(name)
        if nkey in by_key and art and not by_key[nkey].get("boxArtUrl"):
            by_key[nkey]["boxArtUrl"] = art
            enriched += 1
            continue
        kid = "seed-hlj-" + hashlib.md5(f"{grade}|{name}".encode()).hexdigest()[:10]
        kit = {
            "id": kid,
            "name": name,
            "series": "Gundam",
            "grade": grade,
            "scale": SCALE.get(grade, "1/144"),
            "releaseYear": 2020,
            "partCount": None,
            "modelNumber": h["name"][:80],
            "barcode": None,
            "boxArtUrl": art,
            "description": None,
            "isBandai": True,
            "tags": ["HLJ", "BoxArt"] if art else ["HLJ"],
        }
        kits.append(kit)
        by_key[key] = kit
        by_key.setdefault(nkey, kit)
        added += 1

    for g in gdb:
        name = (g.get("name") or "").strip()
        if not name:
            continue
        grade_raw = (g.get("grade") or "HG").strip()
        grade_map = {
            "HG": "HG", "RG": "RG", "MG": "MG", "MGEX": "MGEX", "PG": "PG",
            "SD": "SD", "MGSD": "SD", "SDEX": "SD", "EG": "Other", "FM": "Other",
            "RE-100": "Other", "RE/100": "Other", "P-Bandai": "P-Bandai",
        }
        grade = grade_map.get(grade_raw, "Other")
        desc = g.get("description") or ""
        if "p-bandai" in desc.lower() or g.get("pBandai"):
            grade = "P-Bandai"
        year = 2000
        rel = str(g.get("release") or g.get("releaseDate") or "")
        ym = re.findall(r"((?:19|20)\d{2})", rel)
        if ym:
            year = int(ym[0])
        key = norm(name) + "|" + grade
        art = g.get("boxArtUrl") or g.get("image")
        if key in by_key:
            existing = by_key[key]
            if art and not existing.get("boxArtUrl"):
                existing["boxArtUrl"] = art
                enriched += 1
            if desc and not existing.get("description"):
                existing["description"] = desc[:280]
            if year > (existing.get("releaseYear") or 0) and year >= 2024:
                # keep newer release year for recent kits if existing is placeholder
                pass
            continue
        kid = "seed-gdb-" + hashlib.md5(f"gunpladb|{grade}|{name}|{year}".encode()).hexdigest()[:10]
        kit = {
            "id": kid,
            "name": name[:120],
            "series": g.get("series") or "Gundam",
            "grade": grade,
            "scale": SCALE.get(grade, "1/144"),
            "releaseYear": year,
            "partCount": g.get("partCount"),
            "modelNumber": g.get("modelNumber") or f"{grade} {name}"[:80],
            "barcode": g.get("barcode"),
            "boxArtUrl": art,
            "description": (desc[:280] if desc else None),
            "isBandai": True,
            "tags": ["GunplaDB"] + (["BoxArt"] if art else []),
        }
        kits.append(kit)
        by_key[key] = kit
        added += 1

    # Drop sources key for Swift safety / keep version bump
    payload = {
        "version": 2,
        "updatedAt": date.today().isoformat(),
        "kits": kits,
    }
    SEED.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    with_art = sum(1 for k in kits if k.get("boxArtUrl"))
    print(f"kits={len(kits)} with_art={with_art} added={added} enriched={enriched}")


if __name__ == "__main__":
    main()
