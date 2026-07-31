#!/usr/bin/env bash
# Generates iOS AppIcon sizes from a 1024×1024 master PNG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MASTER="${1:-$ROOT/GunplaVault/Resources/Brand/app-icon-master.png}"
OUT="$ROOT/GunplaVault/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$MASTER" ]]; then
  echo "Master icon not found: $MASTER" >&2
  exit 1
fi

mkdir -p "$OUT"

declare -a SIZES=(
  "20:1:Icon-20@1x.png"
  "20:2:Icon-20@2x.png"
  "20:3:Icon-20@3x.png"
  "29:1:Icon-29@1x.png"
  "29:2:Icon-29@2x.png"
  "29:3:Icon-29@3x.png"
  "40:1:Icon-40@1x.png"
  "40:2:Icon-40@2x.png"
  "40:3:Icon-40@3x.png"
  "60:2:Icon-60@2x.png"
  "60:3:Icon-60@3x.png"
  "76:1:Icon-76@1x.png"
  "76:2:Icon-76@2x.png"
  "83.5:2:Icon-83.5@2x.png"
  "1024:1:Icon-1024.png"
)

for entry in "${SIZES[@]}"; do
  IFS=':' read -r base scale filename <<< "$entry"
  pixels=$(python3 -c "print(int(float('$base') * float('$scale')))")
  sips -z "$pixels" "$pixels" "$MASTER" --out "$OUT/$filename" >/dev/null
  echo "Wrote $filename (${pixels}px)"
done

APP_LOGO_OUT="$ROOT/GunplaVault/Resources/Assets.xcassets/AppLogo.imageset"
mkdir -p "$APP_LOGO_OUT"
cp "$OUT/Icon-1024.png" "$APP_LOGO_OUT/AppLogo.png"
echo "Synced AppLogo.png for in-app branding"

cat > "$OUT/Contents.json" <<'JSON'
{
  "images": [
    { "filename": "Icon-20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20" },
    { "filename": "Icon-20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20" },
    { "filename": "Icon-29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29" },
    { "filename": "Icon-29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29" },
    { "filename": "Icon-40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40" },
    { "filename": "Icon-40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40" },
    { "filename": "Icon-60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60" },
    { "filename": "Icon-60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60" },
    { "filename": "Icon-20@1x.png", "idiom": "ipad", "scale": "1x", "size": "20x20" },
    { "filename": "Icon-20@2x.png", "idiom": "ipad", "scale": "2x", "size": "20x20" },
    { "filename": "Icon-29@1x.png", "idiom": "ipad", "scale": "1x", "size": "29x29" },
    { "filename": "Icon-29@2x.png", "idiom": "ipad", "scale": "2x", "size": "29x29" },
    { "filename": "Icon-40@1x.png", "idiom": "ipad", "scale": "1x", "size": "40x40" },
    { "filename": "Icon-40@2x.png", "idiom": "ipad", "scale": "2x", "size": "40x40" },
    { "filename": "Icon-76@1x.png", "idiom": "ipad", "scale": "1x", "size": "76x76" },
    { "filename": "Icon-76@2x.png", "idiom": "ipad", "scale": "2x", "size": "76x76" },
    { "filename": "Icon-83.5@2x.png", "idiom": "ipad", "scale": "2x", "size": "83.5x83.5" },
    { "filename": "Icon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
JSON

echo "App icons written to $OUT"
