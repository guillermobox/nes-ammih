from pathlib import Path
import struct
import sys

from PIL import Image


class WrongImage(Exception):
    pass


with open(Path(__file__).parent / "mesen.pal", "rb") as fh:
    MESEN_PALETTE = list(struct.iter_unpack("BBB", fh.read()))


def color_distance(a, b):
    return sum(abs(a[i] - b[i]) for i in range(3))


def mesen_palette_match(color):
    closest = sorted(MESEN_PALETTE, key=lambda col: color_distance(col, color))[0]
    exact = closest == color
    return exact, MESEN_PALETTE.index(closest)


def image_as_tiles(path, colormap):
    img = Image.open(path)
    if img.format != "PNG":
        raise WrongImage(f"{path} is not a png")
    palette = extract_color_palette(img, colormap)
    return split_image(img), palette


def extract_color_palette(img, colormap):
    def color_to_string(color):
        if color[3] == 0:
            return "transparent"
        else:
            exact, index = mesen_palette_match(color)
            return (
                f"0x{color[0]:02X}{color[1]:02X}{color[2]:02X}"
                f"(palette {index:02X} {'exact' if exact else 'similar'})"
            )

    colors = img.getcolors()
    if len(colors) > 4:
        raise WrongImage(f"{path} has too many colors")

    palette = dict()
    for count, color in colors:
        if color[3] == 255:
            asint = (color[0] << 16) + (color[1] << 8) + color[2]
        else:
            asint = None

        if asint is None:
            palette[color] = 0
        elif asint in colormap:
            palette[color] = colormap[asint]
        else:
            print(
                f"I don't know this color! {count:3} pixels of color {color_to_string(color)}"
            )

    return palette


def split_image(img):
    if img.width % 8 != 0:
        raise WrongImage(f"{path} width is not a multiple of 8: {img.width}")
    if img.height % 8 != 0:
        raise WrongImage(f"{path} height is not a multiple of 8: {img.height}")

    rows = img.height // 8
    cols = img.width // 8

    for row in range(rows):
        for col in range(cols):
            box = (col * 8, row * 8, (col + 1) * 8, (row + 1) * 8)
            crop = img.crop(box)
            yield row, col, crop.load()
