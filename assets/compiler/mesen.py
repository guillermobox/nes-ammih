from pathlib import Path
import struct
from PIL import Image, ImageDraw

with open(Path(__file__).parent / "mesen.pal", "rb") as fh:
    MESEN_PALETTE = list(struct.iter_unpack("BBB", fh.read()))

rows, cols = 4, 16
cellsize = 32

img = Image.new("RGB", (cols * cellsize, rows * cellsize))
ctx = ImageDraw.Draw(img)

for row in range(rows):
    for col in range(cols):
        idx = row * cols + col
        x0, y0 = col * cellsize, row * cellsize
        x1, y1 = x0 + cellsize, y0 + cellsize
        ctx.rectangle((x0, y0, x1, y1), fill=MESEN_PALETTE[idx])

img.save("mesen.png")
