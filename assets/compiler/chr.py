from pathlib import Path
import sys
import yaml

from .serialize import print_symbols
from .image import image_as_tiles

def encode_8x8_img(img, palette):
    """ Encode a 8x8 pixel image using an specific palette """
    ans = bytearray(0x10)
    for i in range(8):
        for j in range(8):
            pixel = palette[img[j,i]]
            left = pixel & 0x01
            right = pixel >> 1
            ans[i] = (ans[i] << 1) + left
            ans[i + 8] = (ans[i + 8] << 1) + right
    return ans

def main():
    with open(sys.argv[1], "r") as fh:
        cfg = yaml.safe_load(fh)

    offset = 0
    memory = bytearray(8192)

    symbols = {}
    for section in cfg:
        path = Path(sys.argv[1]).parent / section["file"]

        tiles, palette = image_as_tiles(path, section.get('colors', {}))
        name = "METATILE_" + path.name.rstrip(path.suffix).upper()

        symbols[name] = offset >> 4

        if section.get('order') == 'column':
            tiles = sorted(tiles, key=lambda i: i[1])
        else:
            tiles = sorted(tiles, key=lambda i: i[0])

        for _, _, tile in tiles:
            encoded = encode_8x8_img(tile, palette)
            memory[offset : offset + 16] = encoded
            offset += 16

    with open("assets/chr.s", "w") as fh:
        print_symbols(symbols, file=fh)
    with open("assets/chr.bin", "wb") as fh:
        fh.write(memory)


if __name__ == "__main__":
    main()
