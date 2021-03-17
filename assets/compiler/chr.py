import configparser
import struct
import sys
import yaml
from pathlib import Path
from PIL import Image

from .serialize import print_symbols

with open(Path(__file__).parent / "mesen.pal", "rb") as fh:
    MESEN_PALETTE = list(struct.iter_unpack("BBB", fh.read()))


def mesen_palette_match(color):
    c = (color[0], color[1], color[2])

    def dist(a, b):
        return sum(abs(a[i] - b[i]) for i in range(3))

    closest = sorted(MESEN_PALETTE, key=lambda col: dist(col, c))[0]

    exact = closest == c
    return exact, MESEN_PALETTE.index(closest)


class SolidTile:
    def __init__(self, value):
        self.value = value

    def encode(self):
        """ Encode the tile to chr format """
        ans = bytearray(0x10)
        for i in range(8):
            for j in range(8):
                left = self.value & 0x01
                right = self.value >> 1
                ans[i] = (ans[i] << 1) + left
                ans[i + 8] = (ans[i + 8] << 1) + right
        return ans


class Tile:
    def __init__(self, data, palette):
        self.data = [palette[data[i, j]] for i in range(8) for j in range(8)]

    def encode(self):
        """ Encode the tile to chr format """
        ans = bytearray(0x10)
        for i in range(8):
            for j in range(8):
                left = self.data[i + 8 * j] & 0x01
                right = self.data[i + 8 * j] >> 1
                ans[i] = (ans[i] << 1) + left
                ans[i + 8] = (ans[i + 8] << 1) + right
        return ans


class Tileset:
    def __init__(self, name, tiles, column=False):
        self.name = name
        self.tiles = tiles
        self.column = column

    def encode(self):
        if self.column:
            n = len(self.tiles) // 2
            tiles = [self.tiles[j * n + i] for i in (0, 1) for j in range(n)]
            return b"".join(tile.encode() for tile in tiles)
        else:
            return b"".join(tile.encode() for tile in self.tiles)

    @classmethod
    def from_section(cls, section, workdir):
        if section["file"] == "SOLID":
            return cls("solid", [SolidTile(value) for value in range(4)])

        path = str(workdir / section["file"])

        path = Path(path)
        img = Image.open(path)

        if img.format != "PNG":
            raise Exception(f"{path} is not a png")
        if img.width % 8 != 0:
            raise Exception(f"{path} width is not a multiple of 8: {img.width}")
        if img.height % 8 != 0:
            raise Exception(f"{path} height is not a multiple of 8: {img.height}")

        colors = img.getcolors()
        if len(colors) > 4:
            raise Exception(f"{path} has too many colors")

        def color_to_string(color):
            if color[3] == 0:
                return "transparent"
            else:
                exact, index = mesen_palette_match(color)
                return f"#{color[0]:02X}{color[1]:02X}{color[2]:02X} (palette {index:02X} {'exact' if exact else 'similar'})"

        palette = dict()

        for count, color in colors:
            if color[3] == 255:
                asint = (color[0] << 16) + (color[1] << 8) + color[2]
            else:
                asint = None

            if asint is None:
                palette[color] = 0
            elif asint in section["colors"]:
                palette[color] = section["colors"][asint]
            else:
                print(section["file"], "has this:", section["colors"])
                print(
                    "I don't know this color! {count:3} pixels of color {color_to_string(color)}"
                )

        rows = img.height // 8
        cols = img.width // 8

        tiles = []
        tiles_data = {}
        for row in range(rows):
            for col in range(cols):
                box = (col * 8, row * 8, (col + 1) * 8, (row + 1) * 8)
                tile = img.crop(box)
                tiles_data[(row, col)] = tile
                tiles.append(Tile(tile.load(), palette))

        if section.get("display") == "screen":
            unique = []
            for coords in tiles_data.keys():
                tile = tiles_data[coords]
                if tile not in unique:
                    unique.append(tile)
                tiles_data[coords] = unique.index(tile)

            tiles = []
            for tile in unique:
                tiles.append(Tile(tile.load(), palette))

        return cls(
            path.name.rstrip(path.suffix),
            tiles,
            column=section.get("order", "row") == "column",
        )


def main():
    configfile = sys.argv[1]
    with open(configfile, "r") as fh:
        cfg = yaml.safe_load(fh)

    tilesets = [
        Tileset.from_section(section, Path(sys.argv[1]).parent) for section in cfg
    ]

    chr = bytearray(8192)
    offset = 0

    names = [f"METATILE_{tileset.name.upper()}" for tileset in tilesets]
    maxlen = max(len(name) for name in names)

    symbols = {}
    with open("assets/chr.s", "w") as fh:
        for tileset, name in zip(tilesets, names):
            symbols[name] = offset >> 4
            encoded = tileset.encode()
            length = len(encoded)
            chr[offset : offset + length] = encoded
            offset += length
        print_symbols(symbols, file=fh)

    Path("assets/chr.bin").write_bytes(chr)


if __name__ == "__main__":
    main()
