from PIL import Image
from collections import deque
import os

ROOT = r"C:\dev\unbox-fighters\assets\characters\vampiro"
WIDTH = 300
HEIGHT = 200

SOURCES = {
    "head.png": "_src_head.webp",
    "body.png": "_src_body.webp",
    "legs.png": "_src_legs.webp",
    "body_head.png": "_src_body_head.webp",
    "body_legs.png": "_src_body_legs.webp",
    "full.png": "_src_full.webp",
}


def is_pure_black(r, g, b, a, thr=12):
    # Only kill near-pure black matting — keep dark charcoal clothing.
    return a < 8 or (r <= thr and g <= thr and b <= thr)


def flood_clear_black(im, thr=12):
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    q = deque()

    def try_add(x, y):
        if 0 <= x < w and 0 <= y < h and not visited[y][x]:
            r, g, b, a = px[x, y]
            if is_pure_black(r, g, b, a, thr):
                visited[y][x] = True
                q.append((x, y))

    for x in range(w):
        try_add(x, 0)
        try_add(x, h - 1)
    for y in range(h):
        try_add(0, y)
        try_add(w - 1, y)

    removed = 0
    while q:
        x, y = q.popleft()
        r, g, b, _ = px[x, y]
        px[x, y] = (0, 0, 0, 0)
        removed += 1
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            try_add(x + dx, y + dy)
    return removed


def soft_fringe(im, thr=10):
    """Only clear pure-black pixels that touch transparency (1px AA fringe)."""
    w, h = im.size
    px = im.load()
    to_clear = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0 or not is_pure_black(r, g, b, a, thr):
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    to_clear.append((x, y))
                    break
    for x, y in to_clear:
        r, g, b, _ = px[x, y]
        px[x, y] = (0, 0, 0, 0)
    return len(to_clear)


def fit_canvas(im, width=WIDTH, height=HEIGHT):
    im = im.convert("RGBA")
    n1 = flood_clear_black(im, thr=12)
    n2 = soft_fringe(im, thr=10)
    bbox = im.getbbox()
    if not bbox:
        return Image.new("RGBA", (width, height), (0, 0, 0, 0)), n1, n2
    cropped = im.crop(bbox)
    cw, ch = cropped.size
    scale = min(width / cw, height / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.paste(resized, ((width - nw) // 2, (height - nh) // 2), resized)
    return canvas, n1, n2


def fit_square(im, size=WIDTH):
    return fit_canvas(im, size, size)


def main():
    for out_name, src_name in SOURCES.items():
        src_path = os.path.join(ROOT, src_name)
        out_path = os.path.join(ROOT, out_name)
        result, n1, n2 = fit_canvas(Image.open(src_path), WIDTH, HEIGHT)
        result.save(out_path, "PNG")
        alpha = result.getchannel("A")
        opaque = sum(1 for v in alpha.getdata() if v > 16)
        print(f"{out_name}: {result.size}, opaque_px={opaque}, cleared={n1}+{n2}")


if __name__ == "__main__":
    main()
