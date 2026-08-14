"""Cut a 3x3 character sheet into nine 300x200 PNGs (edge-black to transparent).

Example:
    python tools/slice_character_sheet.py folha.png --id zumbi --name Zumbi --head 5 --body 5 --legs 5 --write-defs
"""

from __future__ import annotations

import argparse
import shutil
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_W = 300
OUT_H = 200
SLOTS = ("head", "body", "legs")
POSES = ("1", "2", "3")
SLOT_LABELS = {"head": "Head", "body": "Body", "legs": "Legs"}
DEFAULT_MAGNETS = {
    "head_down": (0, 74),
    "body_up": (0, -70),
    "body_down": (0, 64),
    "legs_up": (0, -68),
}


def clean_id(raw: str) -> str:
    table = str.maketrans(
        {
            "á": "a",
            "à": "a",
            "ã": "a",
            "â": "a",
            "é": "e",
            "ê": "e",
            "í": "i",
            "ó": "o",
            "ô": "o",
            "õ": "o",
            "ú": "u",
            "ü": "u",
            "ç": "c",
        }
    )
    s = raw.strip().lower().translate(table)
    return "".join(ch for ch in s if ch.isalnum() or ch == "_")


def _is_floodable(r: int, g: int, b: int, a: int) -> bool:
    if a < 10:
        return True
    return r <= 13 and g <= 13 and b <= 13


def flood_edge_black(im: Image.Image) -> None:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = set()
    q = deque()

    def try_add(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h or (x, y) in seen:
            return
        r, g, b, a = px[x, y]
        if not _is_floodable(r, g, b, a):
            return
        seen.add((x, y))
        q.append((x, y))

    for x in range(w):
        try_add(x, 0)
        try_add(x, h - 1)
    for y in range(h):
        try_add(0, y)
        try_add(w - 1, y)
    while q:
        x, y = q.popleft()
        r, g, b, _ = px[x, y]
        px[x, y] = (r, g, b, 0)
        try_add(x - 1, y)
        try_add(x + 1, y)
        try_add(x, y - 1)
        try_add(x, y + 1)


def fit_canvas(im: Image.Image, width: int = OUT_W, height: int = OUT_H) -> Image.Image:
    im = im.convert("RGBA")
    flood_edge_black(im)
    bbox = im.getbbox()
    if not bbox:
        return Image.new("RGBA", (width, height), (0, 0, 0, 0))
    cropped = im.crop(bbox)
    cw, ch = cropped.size
    scale = min(width / cw, height / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.paste(resized, ((width - nw) // 2, (height - nh) // 2), resized)
    return canvas


def slice_sheet(sheet_path: Path, set_id: str, out_dir: Path | None = None) -> list[Path]:
    set_id = clean_id(set_id)
    im = Image.open(sheet_path).convert("RGBA")
    if im.width < 3 or im.height < 3:
        raise ValueError(f"Sheet too small: {sheet_path}")
    cell_w = im.width // 3
    cell_h = im.height // 3
    dest_dir = out_dir if out_dir is not None else ROOT / "assets" / "characters" / set_id
    dest_dir.mkdir(parents=True, exist_ok=True)
    saved: list[Path] = []
    for row, slot in enumerate(SLOTS):
        for col, pose in enumerate(POSES):
            cell = im.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            fitted = fit_canvas(cell)
            dest = dest_dir / f"{set_id}_{slot}-{pose}.png"
            fitted.save(dest, "PNG")
            saved.append(dest)
    if out_dir is None:
        keep = dest_dir / f"{set_id}{sheet_path.suffix.lower()}"
        if sheet_path.resolve() != keep.resolve():
            shutil.copy2(sheet_path, keep)
    return saved


def tier_for(value: int) -> int:
    if value <= 5:
        return 1
    if value == 6:
        return 2
    if value == 7:
        return 3
    if value == 8:
        return 4
    return 5


def _magnet_lines(slot: str) -> str:
    if slot == "head":
        x, y = DEFAULT_MAGNETS["head_down"]
        return f"magnet_down = Vector2({x}, {y})\n"
    if slot == "legs":
        x, y = DEFAULT_MAGNETS["legs_up"]
        return f"magnet_up = Vector2({x}, {y})\n"
    ux, uy = DEFAULT_MAGNETS["body_up"]
    dx, dy = DEFAULT_MAGNETS["body_down"]
    return f"magnet_up = Vector2({ux}, {uy})\nmagnet_down = Vector2({dx}, {dy})\nmagnet_weapon = Vector2(0, 0)\n"


def write_defs(set_id: str, display_name: str, head: int, body: int, legs: int) -> list[Path]:
    set_id = clean_id(set_id)
    if not display_name.strip():
        display_name = set_id.capitalize()
    values = {"head": head, "body": body, "legs": legs}
    parts_dir = ROOT / "data" / "parts"
    parts_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for slot in SLOTS:
        combat = values[slot]
        path = parts_dir / f"{set_id}_{slot}.tres"
        slot_type = {"head": 0, "body": 1, "legs": 2}[slot]
        text = (
            '[gd_resource type="Resource" script_class="PartDef" load_steps=5 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/data/part_def.gd" id="1"]\n'
            f'[ext_resource type="Texture2D" path="res://assets/characters/{set_id}/{set_id}_{slot}-1.png" id="2"]\n'
            f'[ext_resource type="Texture2D" path="res://assets/characters/{set_id}/{set_id}_{slot}-2.png" id="3"]\n'
            f'[ext_resource type="Texture2D" path="res://assets/characters/{set_id}/{set_id}_{slot}-3.png" id="4"]\n\n'
            "[resource]\n"
            'script = ExtResource("1")\n'
            f'id = &"{set_id}_{slot}"\n'
            f'display_name = "{display_name} {SLOT_LABELS[slot]}"\n'
            f"slot_type = {slot_type}\n"
            'sprite = ExtResource("2")\n'
            'sprite_profile = ExtResource("3")\n'
            'sprite_attack = ExtResource("4")\n'
            f'set_id = &"{set_id}"\n'
            f"combat_value = {combat}\n"
            f"tier = {tier_for(combat)}\n"
            f"{_magnet_lines(slot)}"
        )
        path.write_text(text, encoding="utf-8")
        written.append(path)
    char_path = parts_dir / f"{set_id}_character.tres"
    char_path.write_text(
        (
            '[gd_resource type="Resource" script_class="CharacterDef" load_steps=5 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/data/character_def.gd" id="1"]\n'
            f'[ext_resource type="Resource" path="res://data/parts/{set_id}_head.tres" id="2"]\n'
            f'[ext_resource type="Resource" path="res://data/parts/{set_id}_body.tres" id="3"]\n'
            f'[ext_resource type="Resource" path="res://data/parts/{set_id}_legs.tres" id="4"]\n\n'
            "[resource]\n"
            'script = ExtResource("1")\n'
            f'id = &"{set_id}"\n'
            f'display_name = "{display_name}"\n'
            'head = ExtResource("2")\n'
            'body = ExtResource("3")\n'
            'legs = ExtResource("4")\n'
        ),
        encoding="utf-8",
    )
    written.append(char_path)
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description="Cut a 3x3 Freak sheet into nine 300x200 parts.")
    parser.add_argument("sheet", type=Path, help="PNG or WEBP grid 3x3, preferably 900x600")
    parser.add_argument("--id", required=True, help="Internal id, e.g. zumbi")
    parser.add_argument("--name", default="", help="Name on the card, e.g. Zumbi")
    parser.add_argument("--head", type=int, default=4)
    parser.add_argument("--body", type=int, default=4)
    parser.add_argument("--legs", type=int, default=4)
    parser.add_argument("--write-defs", action="store_true", help="Also create the .tres files in data/parts")
    args = parser.parse_args()
    set_id = clean_id(args.id)
    if not set_id:
        raise SystemExit("Id interno inválido. Use minúsculo, sem acento. Exemplo: zumbi.")
    saved = slice_sheet(args.sheet, set_id)
    print(f"cut {len(saved)} pngs into assets/characters/{set_id}/")
    if args.write_defs:
        defs = write_defs(set_id, args.name, args.head, args.body, args.legs)
        print(f"wrote {len(defs)} defs in data/parts/")
    print("Next: open Godot, Project → Tools → Ímãs das Peças, and drag CIMA / BAIXO / ARMA on Frente, De lado, Golpe.")


if __name__ == "__main__":
    main()
