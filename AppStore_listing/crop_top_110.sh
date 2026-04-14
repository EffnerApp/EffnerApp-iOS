#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="/tmp/effner-crop-venv"

cleanup() {
  rm -rf "$VENV_PATH"
}
trap cleanup EXIT

python3 -m venv "$VENV_PATH"
"$VENV_PATH/bin/pip" install --quiet Pillow

cd "$SCRIPT_DIR"
"$VENV_PATH/bin/python" - <<'PY'
from pathlib import Path
from PIL import Image

for p in Path(".").iterdir():
    if p.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        continue
    with Image.open(p) as im:
        w, h = im.size
        if h <= 110:
            continue
        im.crop((0, 110, w, h)).save(p)

for p in sorted(Path(".").iterdir()):
    if p.suffix.lower() in {".png", ".jpg", ".jpeg"}:
        with Image.open(p) as im:
            print(f"{p.name}: {im.size[0]}x{im.size[1]}")
PY
