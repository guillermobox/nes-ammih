import argparse
from pathlib import Path
from PIL import Image


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
                right = self.data[i + 8*j] >> 1
                ans[i] = (ans[i] << 1 ) + left
                ans[i + 8] = (ans[i + 8 ] << 1) +right
        return ans


class Tileset:
    def __init__(self, name, tiles, column=False):
        self.name = name
        self.tiles = tiles
        self.column = column

    def encode(self):
        if self.column:
            n = len(self.tiles) // 2
            tiles = [self.tiles[j * n + i] for i in (0,1) for j in range(n)]
            return b''.join(tile.encode() for tile in tiles)
        else:
            return b''.join(tile.encode() for tile in self.tiles)

    @classmethod
    def guess_palette(cls, colors):
        colors = [color for freq, color in colors]
        return sorted(colors)

    @classmethod
    def from_path(cls, path):
        path, _, modifier = path.partition('@')

        if modifier == 'solid' and path == '':
            return cls('solid', [SolidTile(value) for value in range(4)])

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

        rows = img.height // 8
        cols = img.width // 8

        tiles = []
        for row in range(rows):
            for col in range(cols):
                box = (col * 8, row * 8, (col + 1) * 8, (row + 1) * 8)
                tile = img.crop(box)
                tiles.append(Tile(tile.load(), p))

        return cls(path.name.rstrip(path.suffix), tiles, column=modifier=='column')


def main(config):
    tilesets = [
        Tileset.from_path(path)
        for path in config.tiles
    ]

    chr = bytearray(8192)
    offset = 0

    names = [f'METATILE_{tileset.name.upper()}' for tileset in tilesets]
    maxlen = max(len(name) for name in names)

    with open(config.assembly, 'w') as fh:
        for tileset, name in zip(tilesets, names):
            fh.write(f'{name.ljust(maxlen)} = ${offset >> 4:02x}\n')
            encoded = tileset.encode()
            length = len(encoded)
            chr[offset:offset+length] = encoded
            offset += length

    Path(config.binary).write_bytes(chr)


def parse_args():
    parser = argparse.ArgumentParser(description='Tiler assembles chr rom files from png tiles')
    parser.add_argument('tiles', nargs='+', help='png files to assemble')
    parser.add_argument('--binary', help='output file to write the chr binary')
    parser.add_argument('--assembly', help='output addresses to this file')
    return parser.parse_args()


if __name__ == '__main__':
    config = parse_args()
    main(config)
