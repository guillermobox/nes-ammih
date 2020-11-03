import argparse
import configparser
import struct
import sys
from pathlib import Path
from PIL import Image

mesenpalette = bytearray(
    [
        0x66,
        0x66,
        0x66,
        0x00,
        0x2A,
        0x88,
        0x14,
        0x12,
        0xA7,
        0x3B,
        0x00,
        0xA4,
        0x5C,
        0x00,
        0x7E,
        0x6E,
        0x00,
        0x40,
        0x6C,
        0x06,
        0x00,
        0x56,
        0x1D,
        0x00,
        0x33,
        0x35,
        0x00,
        0x0B,
        0x48,
        0x00,
        0x00,
        0x52,
        0x00,
        0x00,
        0x4F,
        0x08,
        0x00,
        0x40,
        0x4D,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xAD,
        0xAD,
        0xAD,
        0x15,
        0x5F,
        0xD9,
        0x42,
        0x40,
        0xFF,
        0x75,
        0x27,
        0xFE,
        0xA0,
        0x1A,
        0xCC,
        0xB7,
        0x1E,
        0x7B,
        0xB5,
        0x31,
        0x20,
        0x99,
        0x4E,
        0x00,
        0x6B,
        0x6D,
        0x00,
        0x38,
        0x87,
        0x00,
        0x0C,
        0x93,
        0x00,
        0x00,
        0x8F,
        0x32,
        0x00,
        0x7C,
        0x8D,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xFF,
        0xFE,
        0xFF,
        0x64,
        0xB0,
        0xFF,
        0x92,
        0x90,
        0xFF,
        0xC6,
        0x76,
        0xFF,
        0xF3,
        0x6A,
        0xFF,
        0xFE,
        0x6E,
        0xCC,
        0xFE,
        0x81,
        0x70,
        0xEA,
        0x9E,
        0x22,
        0xBC,
        0xBE,
        0x00,
        0x88,
        0xD8,
        0x00,
        0x5C,
        0xE4,
        0x30,
        0x45,
        0xE0,
        0x82,
        0x48,
        0xCD,
        0xDE,
        0x4F,
        0x4F,
        0x4F,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xFF,
        0xFE,
        0xFF,
        0xC0,
        0xDF,
        0xFF,
        0xD3,
        0xD2,
        0xFF,
        0xE8,
        0xC8,
        0xFF,
        0xFB,
        0xC2,
        0xFF,
        0xFE,
        0xC4,
        0xEA,
        0xFE,
        0xCC,
        0xC5,
        0xF7,
        0xD8,
        0xA5,
        0xE4,
        0xE5,
        0x94,
        0xCF,
        0xEF,
        0x96,
        0xBD,
        0xF4,
        0xAB,
        0xB3,
        0xF3,
        0xCC,
        0xB5,
        0xEB,
        0xF2,
        0xB8,
        0xB8,
        0xB8,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
    ]
)
palette = list(struct.iter_unpack("BBB", mesenpalette))


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
                pal = palette[idx]
                guess.append((*pal, 255))
        else:
            guess.extend(colors)
        return guess

    @classmethod
    def from_section(cls, section, workdir):
        if section.name == "@SOLID@":
            return cls("solid", [SolidTile(value) for value in range(4)])

        path = str(workdir / section.name)

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
                palette.index(sorted(palette, key=lambda col: dist(col, c))[0])
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
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("configuration")
    args = parser.parse_args()

    cfg = configparser.ConfigParser()
    cfg.read(args.configuration)

    tilesets = [
        Tileset.from_section(cfg[section], Path(sys.argv[1]).parent)
        for section in cfg.sections()
    ]

    chr = bytearray(8192)
    offset = 0

    names = [f"METATILE_{tileset.name.upper()}" for tileset in tilesets]
    maxlen = max(len(name) for name in names)

    with open("chr.s", "w") as fh:
        for tileset, name in zip(tilesets, names):
            fh.write(f"{name.ljust(maxlen)} = ${offset >> 4:02x}")
            if tileset.palette:
                formatted_palette = ",".join(f"${p:02x}" for p in tileset.palette)
                fh.write(f" ; palette: {formatted_palette}")
            fh.write("\n")
            encoded = tileset.encode()
            length = len(encoded)
            chr[offset : offset + length] = encoded
            offset += length

    Path("chr.bin").write_bytes(chr)


if __name__ == "__main__":
    main()
