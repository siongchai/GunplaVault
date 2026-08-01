#!/usr/bin/env python3
"""Refresh brand logos from the design sheet (light + dark AppLogo variants)."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DESIGN_SHEET = ROOT / "icon and splash screen.PNG"
ASSETS = ROOT / "GunplaVault/Resources/Assets.xcassets"
LOGO_DIR = ASSETS / "AppLogo.imageset"


def write_colorset(name: str, light: tuple[float, float, float], dark: tuple[float, float, float]) -> None:
    path = ASSETS / f"{name}.colorset"
    path.mkdir(parents=True, exist_ok=True)

    def components(rgb: tuple[float, float, float]) -> dict:
        r, g, b = rgb
        return {
            "alpha": "1.000",
            "blue": f"{b:.3f}",
            "green": f"{g:.3f}",
            "red": f"{r:.3f}",
        }

    payload = {
        "colors": [
            {
                "color": {"color-space": "srgb", "components": components(light)},
                "idiom": "universal",
            },
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "color": {"color-space": "srgb", "components": components(dark)},
                "idiom": "universal",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (path / "Contents.json").write_text(json.dumps(payload, indent=2) + "\n")


def main() -> None:
    if not DESIGN_SHEET.exists():
        raise SystemExit(f"Design sheet not found: {DESIGN_SHEET}")

    sheet = Image.open(DESIGN_SHEET)
    light = sheet.crop((88, 72, 318, 302)).resize((1024, 1024), Image.Resampling.LANCZOS)
    dark = sheet.crop((950, 70, 1150, 270)).resize((1024, 1024), Image.Resampling.LANCZOS)

    LOGO_DIR.mkdir(parents=True, exist_ok=True)
    light.save(LOGO_DIR / "AppLogo-light.png")
    dark.save(LOGO_DIR / "AppLogo-dark.png")
    light.save(LOGO_DIR / "AppLogo.png")

    (LOGO_DIR / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"filename": "AppLogo-light.png", "idiom": "universal", "scale": "1x"},
                    {
                        "appearances": [{"appearance": "luminosity", "value": "dark"}],
                        "filename": "AppLogo-dark.png",
                        "idiom": "universal",
                        "scale": "1x",
                    },
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
        + "\n"
    )

    write_colorset("SplashBackground", (0.969, 0.969, 0.980), (0.059, 0.071, 0.102))
    write_colorset("SplashAccent", (0.20, 0.45, 0.95), (0.55, 0.36, 0.98))
    write_colorset("SplashInk", (0.10, 0.12, 0.18), (0.96, 0.96, 0.98))

    print("Refreshed AppLogo + splash colors from design sheet.")


if __name__ == "__main__":
    main()
