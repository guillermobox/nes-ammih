import configparser
import struct
import sys
from pathlib import Path
from PIL import Image

mesenpalette = bytearray([
  0x66, 0x66, 0x66, 0x00, 0x2a, 0x88, 0x14, 0x12, 0xa7, 0x3b, 0x00, 0xa4,
  0x5c, 0x00, 0x7e, 0x6e, 0x00, 0x40, 0x6c, 0x06, 0x00, 0x56, 0x1d, 0x00,
  0x33, 0x35, 0x00, 0x0b, 0x48, 0x00, 0x00, 0x52, 0x00, 0x00, 0x4f, 0x08,
  0x00, 0x40, 0x4d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xad, 0xad, 0xad, 0x15, 0x5f, 0xd9, 0x42, 0x40, 0xff, 0x75, 0x27, 0xfe,
  0xa0, 0x1a, 0xcc, 0xb7, 0x1e, 0x7b, 0xb5, 0x31, 0x20, 0x99, 0x4e, 0x00,
  0x6b, 0x6d, 0x00, 0x38, 0x87, 0x00, 0x0c, 0x93, 0x00, 0x00, 0x8f, 0x32,
  0x00, 0x7c, 0x8d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xff, 0xfe, 0xff, 0x64, 0xb0, 0xff, 0x92, 0x90, 0xff, 0xc6, 0x76, 0xff,
  0xf3, 0x6a, 0xff, 0xfe, 0x6e, 0xcc, 0xfe, 0x81, 0x70, 0xea, 0x9e, 0x22,
  0xbc, 0xbe, 0x00, 0x88, 0xd8, 0x00, 0x5c, 0xe4, 0x30, 0x45, 0xe0, 0x82,
  0x48, 0xcd, 0xde, 0x4f, 0x4f, 0x4f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xff, 0xfe, 0xff, 0xc0, 0xdf, 0xff, 0xd3, 0xd2, 0xff, 0xe8, 0xc8, 0xff,
  0xfb, 0xc2, 0xff, 0xfe, 0xc4, 0xea, 0xfe, 0xcc, 0xc5, 0xf7, 0xd8, 0xa5,
  0xe4, 0xe5, 0x94, 0xcf, 0xef, 0x96, 0xbd, 0xf4, 0xab, 0xb3, 0xf3, 0xcc,
  0xb5, 0xeb, 0xf2, 0xb8, 0xb8, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  ])
palette = list(struct.iter_unpack('BBB', mesenpalette))


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
                ans[i] = (ans[i] << 1 ) + left
                ans[i + 8] = (ans[i + 8 ] << 1) +right
        return ans

class Tile:
    def __init__(self, data, palette):
        self.data = [
                palette.index(data[i,j])
                for i in range(8)
                for j in range(8)
           ]

    def encode(self):
        """ Encode the tile to chr format """
        if not any(self.data):
            return b""
        ans = bytearray(0x10)
        for i in range(8):
            for j in range(8):
                left = self.data[i + 8 * j] & 0x01
                right = self.data[i + 8 * j] >> 1
                ans[i] = (ans[i] << 1 ) + left
                ans[i + 8] = (ans[i + 8 ] << 1) + right
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
            tiles = [self.tiles[j * n + i] for i in (0,1) for j in range(n)]
            return b''.join(tile.encode() for tile in tiles)
        else:
            return b''.join(tile.encode() for tile in self.tiles)

    @classmethod
    def guess_palette(cls, colors):
        colors = [color for freq, color in colors if color != (0,0,0,0)]
        return [(0,0,0,0)] + sorted(colors)

    @classmethod
    def from_section(cls, section, workdir):
        if section.name == '@SOLID@':
            return cls('solid', [SolidTile(value) for value in range(4)])

        path = str(workdir / section.name)
        path, _, modifier = path.partition('@')

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
        p = Tileset.guess_palette(colors)
        suggested = []

        for color in p[1:]:
            c = (color[0], color[1], color[2])
            def dist(a,b):
                return sum(abs(a[i]-b[i]) for i in range(3))
            suggested.append(palette.index(sorted(palette, key=lambda col:dist(col,c))[0]))

        rows = img.height // 8
        cols = img.width // 8

        tiles = []
        for row in range(rows):
            for col in range(cols):
                box = (col * 8, row * 8, (col + 1) * 8, (row + 1) * 8)
                tile = img.crop(box)
                tiles.append(Tile(tile.load(), p))

        return cls(path.name.rstrip(path.suffix), tiles, palette=suggested, column=section.get('order', 'row')=='column')


def main():
    cfg = configparser.ConfigParser()
    cfg.read(sys.argv[1])

    tilesets = [
        Tileset.from_section(cfg[section], Path(sys.argv[1]).parent)
        for section in cfg.sections()
    ]

    chr = bytearray(8192)
    offset = 0

    names = [f'METATILE_{tileset.name.upper()}' for tileset in tilesets]
    maxlen = max(len(name) for name in names)

    with open('chr.s', 'w') as fh:
        for tileset, name in zip(tilesets, names):
            fh.write(f'{name.ljust(maxlen)} = ${offset >> 4:02x}')
            if tileset.palette:
                formatted_palette = ','.join(f'${p:02x}' for p in tileset.palette)
                fh.write(f' ; palette: {formatted_palette}')
            fh.write('\n')
            encoded = tileset.encode()
            length = len(encoded)
            chr[offset:offset+length] = encoded
            offset += length

    Path('chr.bin').write_bytes(chr)


if __name__ == '__main__':
    main()
