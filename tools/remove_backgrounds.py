from PIL import Image
from collections import deque
import os

ROOT = r"C:\dev\unbox-fighters\assets"


def is_checker(r, g, b, a=255):
    if a < 10:
        return True
    # Classic transparency checker: light gray (~204) and mid gray (~153)
    if abs(r - g) > 18 or abs(g - b) > 18:
        return False
    avg = (r + g + b) / 3.0
    return 130 <= avg <= 230


def is_near_color(p, ref, tol):
    return all(abs(int(p[i]) - int(ref[i])) <= tol for i in range(3))


def is_near_black(r, g, b, thr=28):
    return r <= thr and g <= thr and b <= thr


def flood_remove(im, predicate, neighbors8=True):
    """Set alpha=0 for edge-connected pixels matching predicate."""
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    q = deque()

    def enqueue(x, y):
        if 0 <= x < w and 0 <= y < h and not visited[y][x]:
            r, g, b, a = px[x, y]
            if predicate(r, g, b, a):
                visited[y][x] = True
                q.append((x, y))

    for x in range(w):
        enqueue(x, 0)
        enqueue(x, h - 1)
    for y in range(h):
        enqueue(0, y)
        enqueue(w - 1, y)

    deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    if neighbors8:
        deltas += [(-1, -1), (1, -1), (-1, 1), (1, 1)]

    removed = 0
    while q:
        x, y = q.popleft()
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 0)
        removed += 1
        for dx, dy in deltas:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                nr, ng, nb, na = px[nx, ny]
                if predicate(nr, ng, nb, na):
                    visited[ny][nx] = True
                    q.append((nx, ny))
    return removed


def remove_checkerboard(im):
    # First pass: mark obvious checker pixels anywhere near edges via flood
    removed = flood_remove(im, lambda r, g, b, a: is_checker(r, g, b, a) or a < 10)
    # Second: also clear isolated checker pixels that weren't edge-connected tightly
    w, h = im.size
    px = im.load()
    extra = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and is_checker(r, g, b, a):
                px[x, y] = (r, g, b, 0)
                extra += 1
    return removed + extra


def remove_solid_bg(im, tol=28):
    w, h = im.size
    px = im.load()
    # Use multiple corner refs
    refs = [px[2, 2][:3], px[w - 3, 2][:3], px[2, h - 3][:3], px[w - 3, h - 3][:3]]

    def pred(r, g, b, a):
        if a < 10:
            return True
        return any(is_near_color((r, g, b), ref, tol) for ref in refs)

    return flood_remove(im, pred)


def remove_black_bg(im, thr=22):
    return flood_remove(im, lambda r, g, b, a: a < 10 or is_near_black(r, g, b, thr))


def trim_transparent(im, pad=2):
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(im.width, r + pad)
    b = min(im.height, b + pad)
    return im.crop((l, t, r, b))


def process_ui(path, out_path):
    im = Image.open(path).convert("RGBA")
    n1 = remove_checkerboard(im)
    n2 = remove_solid_bg(im, tol=32)
    im = trim_transparent(im)
    im.save(out_path, "PNG")
    print(f"UI {os.path.basename(path)}: checker/solid removed~{n1}+{n2}, saved {out_path} {im.size}")


def process_vamp(path, out_path):
    im = Image.open(path).convert("RGBA")
    n = remove_black_bg(im, thr=24)
    # Soft fringe cleanup: kill near-black with low saturation still edge-ish leftover
    w, h = im.size
    px = im.load()
    extra = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # leftover anti-aliased dark fringe against old black bg
            if r <= 18 and g <= 18 and b <= 18:
                # only if majority of neighbors transparent
                trans = 0
                tot = 0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            tot += 1
                            if px[nx, ny][3] == 0:
                                trans += 1
                if tot and trans / tot >= 0.45:
                    px[x, y] = (r, g, b, 0)
                    extra += 1
    im = trim_transparent(im)
    im.save(out_path, "PNG")
    print(f"VAMP {os.path.basename(path)}: removed~{n}+{extra}, saved {out_path} {im.size}")


def main():
    ui_dir = os.path.join(ROOT, "ui")
    for name in ["frame_premium.png", "crate_premium.png", "shelf_premium.png"]:
        process_ui(os.path.join(ui_dir, name), os.path.join(ui_dir, name))

    vamp_dir = os.path.join(ROOT, "characters", "vampiro")
    mapping = [
        "head.webp",
        "body.webp",
        "legs.webp",
        "body_head.webp",
        "body_legs.webp",
        "full.webp",
    ]
    for name in mapping:
        src = os.path.join(vamp_dir, name)
        out = os.path.join(vamp_dir, name.replace(".webp", ".png"))
        process_vamp(src, out)

    print("DONE")


if __name__ == "__main__":
    main()
