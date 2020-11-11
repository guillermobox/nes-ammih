import configparser
import struct
import sys
import yaml
from pathlib import Path
from PIL import Image

from asset_compiler.serialize import print_symbols

with open(Path(__file__).parent / "mesen.pal", "rb") as fh:
    MESEN_PALETTE = list(struct.iter_unpack("BBB", fh.read()))


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
        self.data = [palette.index(data[i, j]) for i in range(8) for j in range(8)]

    def encode(self):
        """ Encode the tile to chr format """
        if not any(self.data):
            return b""
        ans = bytearray(0x10)
        for i in range(8):
            for j in range(8):
                left = self.data[i + 8 * j] & 0x01
                right = self.data[i + 8 * j] >> 1
                ans[i] = (ans[i] << 1) + left
                ans[i + 8] = (ans[i + 8] << 1) + right
        return ans


class Tileset:
    def __init__(self, name, tiles, palette=None, column=False):
        self.name = name
        self.tiles = tiles
        self.column = column
        self.palette = palette

    def encode(self):
        if self.column:
            n = len(self.tiles) // 2
            tiles = [self.tiles[j * n + i] for i in (0, 1) for j in range(n)]
            return b"".join(tile.encode() for tile in tiles)
        else:
            return b"".join(tile.encode() for tile in self.tiles)

    @classmethod
    def guess_palette(cls, colors, section):
        transparent = (0, 0, 0, 0)
        colors = sorted([color for freq, color in colors if color != (0, 0, 0, 0)])

        guess = [transparent]

        fixed_colors = False
        for i in range(1, 4):
            if f"color{i}" in section:
                fixed_colors = True

        if fixed_colors == True:
            for i in range(1, 4):
                if f"color{i}" not in section:
                    guess.append(transparent)
                    continue
                palindex = section[f"color{i}"]
                if palindex.startswith("$"):
                    idx = int(palindex[1:], 16)
                elif palindex.startswith("#"):
                    r = int(palindex[1:3], 16)
                    g = int(palindex[3:5], 16)
                    b = int(palindex[5:7], 16)
                    guess.append((r, g, b, 255))
                    continue
                else:
                    idx = int(palindex)
                pal = MESEN_PALETTE[idx]
                guess.append((*pal, 255))
        else:
            guess.extend(colors)
        return guess

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
        p = Tileset.guess_palette(colors, section)

        suggested = []

        for color in p[1:]:
            c = (color[0], color[1], color[2])

            def dist(a, b):
                return sum(abs(a[i] - b[i]) for i in range(3))

            suggested.append(
                MESEN_PALETTE.index(
                    sorted(MESEN_PALETTE, key=lambda col: dist(col, c))[0]
                )
            )

        rows = img.height // 8
        cols = img.width // 8

        tiles = []
        for row in range(rows):
            for col in range(cols):
                box = (col * 8, row * 8, (col + 1) * 8, (row + 1) * 8)
                tile = img.crop(box)
                tiles.append(Tile(tile.load(), p))

        return cls(
            path.name.rstrip(path.suffix),
            tiles,
            palette=suggested,
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
