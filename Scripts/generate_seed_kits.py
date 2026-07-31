#!/usr/bin/env python3
"""Generate seed_kits.json with ~500 Gunpla catalog entries."""

import json
import hashlib
from datetime import date

SERIES = {
    "Mobile Suit Gundam": ["RX-78-2 Gundam", "MS-06S Zaku II", "MS-06F Zaku II", "MS-09 Dom", "MS-07B Gouf", "MS-14A Gelgoog", "RX-77-2 Guncannon", "RX-75 Guntank", "MS-18E Kämpfer", "MSM-07 Z'Gok", "MSN-02 Zeong"],
    "Zeta Gundam": ["MSZ-006 Zeta Gundam", "MSN-00100 Hyaku Shiki", "RMS-099 Rick Dias", "PMX-003 The-O", "MS-09R-2 Rick Dom II", "Nemo", "Barzam"],
    "ZZ Gundam": ["MSZ-010 ZZ Gundam", "MSN-0100 Hyaku Shiki Kai", "AMX-004 Qubeley", "AMX-003 Gaza-C", "AMX-107 Bawoo"],
    "Char's Counterattack": ["RX-93 ν Gundam", "MSN-04 Sazabi", "RX-0 Unicorn Gundam", "RGM-89 Jegan", "Re-GZ"],
    "Gundam Wing": ["XXXG-01W Wing Gundam", "XXXG-01D Gundam Deathscythe", "XXXG-01H Gundam Heavyarms", "XXXG-01S Gundam Sandrock", "XXXG-01R Gundam Maxter", "OZ-00MS Tallgeese", "XXXG-00W0 Wing Gundam Zero", "Wing Gundam EW", "Gundam Deathscythe Hell EW", "Gundam Sandrock EW", "Gundam Heavyarms EW", "Tallgeese III"],
    "Gundam SEED": ["GAT-X105 Strike Gundam", "GAT-X303 Aegis Gundam", "GAT-X102 Duel Gundam", "GAT-X103 Buster Gundam", "GAT-X207 Blitz Gundam", "GAT-X370 Raider Gundam", "ZGMF-X10A Freedom Gundam", "ZGMF-X09A Justice Gundam", "GAT-X105 Strike Rouge", "MBF-P02 Gundam Astray Red Frame", "MBF-P03 Gundam Astray Blue Frame", "MBF-P01 Gundam Astray Gold Frame"],
    "Gundam SEED DESTINY": ["ZGMF-X42S Destiny Gundam", "ZGMF-X20A Strike Freedom Gundam", "ZGMF-X19A Infinite Justice Gundam", "ZGMF-X56S Impulse Gundam", "ZGMF-1001/M Blaze Zaku Phantom", "GOUF Ignited", "Strike Noir", "Legend Gundam", "Akatsuki Gundam"],
    "Iron-Blooded Orphans": ["ASW-G-08 Gundam Barbatos", "ASW-G-11 Gundam Gusion", "ASW-G-01 Gundam Bael", "ASW-G-66 Gundam Kimaris", "ASW-G-64 Gundam Flauros", "EB-06 Graze", "ASW-G-29 Gundam Astaroth", "Gundam Barbatos Lupus", "Gundam Barbatos Lupus Rex", "Gundam Vidar"],
    "The Witch from Mercury": ["XVX-016 Gundam Aerial", "CF-022 Gundam Lfrith", "MD-0064 Darilbalde", "GYAAR Gundam Pharact", "Chuchu's Demi Trainer", "Gundam Aerial Rebuild", "Guel's Dilanza", "Michaelis"],
    "GQuuuuuuX": ["GQuuuuuuX", "Red Gundam", "White Gundam", "Zaku (GQ)", "GM (GQ)"],
    "0083": ["RX-78GP01 Gundam GP01", "RX-78GP02A Gundam GP02A", "RX-78GP03S Gundam GP03S", "MS-09F/trop Dom Tropen"],
    "0080": ["RX-78NT-1 Gundam NT-1", "MS-18E Kämpfer", "MS-06FZ Zaku II Kai", "RGM-79SC GM Sniper Custom"],
    "Thunderbolt": ["FA-78 Full Armor Gundam", "MS-05 Zaku I", "Psycho Zaku", "Atlas Gundam", "GM Cannon"],
    "Build Fighters": ["Build Strike Gundam", "Star Winning Gundam", "Gundam Amazing Red Warrior", "Crossbone Gundam Maoh", "Hot Scramble Gundam"],
    "00": ["GN-001 Gundam Exia", "GN-002 Gundam Dynames", "GN-003 Gundam Kyrios", "GN-005 Gundam Virtue", "GN-0000 Gundam 00", "GN-006 Cherudim Gundam", "GN-007 Arios Gundam", "GN-008 Seravee Gundam", "GN-X", "Gundam Avalanche Exia"],
    "G Gundam": ["GF13-017NJ Shining Gundam", "GF13-017NJII God Gundam", "GF13-006NA Gundam Maxter", "GF13-011NC Dragon Gundam", "GF13-013NR Bolt Gundam", "Master Gundam", "Devil Gundam"],
    "Turn A Gundam": ["SYSTEM ∀-99 ∀ Gundam", "AMX-109 Capule", "MRC-F20 SUMO"],
    "Crossbone Gundam": ["XM-X1 Crossbone Gundam X1", "XM-X2 Crossbone Gundam X2", "XM-X3 Crossbone Gundam X3"],
    "Hathaway's Flash": ["Xi Gundam", "Penelope", "Messala"],
    "0088": ["MSZ-010 ΖΖ Gundam", "AMX-004-2 Qubeley Mk-II", "PMX-000 Messala"],
}

GRADES = ["HG", "RG", "MG", "MGEX", "PG", "SD", "P-Bandai", "Other"]
SCALES = {"HG": "1/144", "RG": "1/144", "MG": "1/100", "MGEX": "1/100", "PG": "1/60", "SD": "SD", "P-Bandai": "1/144", "Other": "1/144"}
VARIANTS = ["", " Ver.Ka", " HWS", " Full Armor", " EW", " Revive", " Titanium Finish", " Clear Color", " (Reissue)", " Coating"]

def kit_id(name: str, grade: str, series: str) -> str:
    raw = f"{name}|{grade}|{series}"
    return "seed-" + hashlib.md5(raw.encode()).hexdigest()[:10]

def part_count(grade: str) -> int:
    base = {"HG": 120, "RG": 250, "MG": 350, "MGEX": 550, "PG": 800, "SD": 80, "P-Bandai": 180, "Other": 150}
    return base.get(grade, 150)

def release_year(series: str, idx: int) -> int:
    era = {
        "Mobile Suit Gundam": 1980, "Zeta Gundam": 1985, "Gundam Wing": 1995,
        "Gundam SEED": 2003, "Iron-Blooded Orphans": 2015, "The Witch from Mercury": 2022,
        "GQuuuuuuX": 2025,
    }
    base = era.get(series, 2000)
    return min(base + (idx % 8), 2025)

def generate():
    kits = []
    seen = set()

    # Preserve curated starter kits
    curated_path = __file__.replace("generate_seed_kits.py", "../GunplaVault/Resources/SeedData/seed_kits_curated.json")
    try:
        with open(curated_path.replace("seed_kits_curated.json", "seed_kits.json")) as f:
            existing = json.load(f)
            for k in existing.get("kits", [])[:10]:
                if k["id"] not in seen:
                    kits.append(k)
                    seen.add(k["id"])
    except FileNotFoundError:
        pass

    for series, suits in SERIES.items():
        for si, suit in enumerate(suits):
            for grade in GRADES:
                if grade == "MGEX" and grade not in suit and "Strike Freedom" not in suit and "ν" not in suit and "Nu" not in suit:
                    continue
                if grade == "PG" and si % 3 != 0:
                    continue
                if grade == "P-Bandai" and si % 4 != 0:
                    continue
                for vi, variant in enumerate(VARIANTS[:3 if grade in ("HG", "RG") else 2]):
                    name = suit + variant
                    if grade == "P-Bandai":
                        name = f"[P-Bandai] {name}"
                    kid = kit_id(name, grade, series)
                    if kid in seen:
                        continue
                    seen.add(kid)
                    tags = [series.split()[0] if series else "Gundam"]
                    if variant.strip():
                        tags.append(variant.strip().strip("()"))
                    if grade == "P-Bandai":
                        tags.append("P-Bandai")
                    kits.append({
                        "id": kid,
                        "name": name,
                        "series": series,
                        "grade": grade if grade != "Other" else "HG",
                        "scale": SCALES.get(grade, "1/144"),
                        "releaseYear": release_year(series, si + vi),
                        "partCount": part_count(grade) + (si * 7) % 120,
                        "modelNumber": f"{grade} {name}",
                        "barcode": None,
                        "boxArtUrl": None,
                        "description": f"{grade} kit of the {name} from {series}.",
                        "isBandai": True,
                        "tags": tags[:4],
                    })
                    if len(kits) >= 520:
                        break
                if len(kits) >= 520:
                    break
            if len(kits) >= 520:
                break
        if len(kits) >= 520:
            break

    return {
        "version": 1,
        "updatedAt": str(date.today()),
        "kits": kits[:520],
    }

if __name__ == "__main__":
    import os
    out = os.path.join(os.path.dirname(__file__), "..", "GunplaVault", "Resources", "SeedData", "seed_kits.json")
    data = generate()
    with open(out, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Wrote {len(data['kits'])} kits to {out}")
