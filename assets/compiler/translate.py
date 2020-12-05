import argparse


def to_ppu(row, col):
    assert row < 30
    assert col < 32
    return 0x2000 + col + row * 0x20


def from_ppu(addr):
    assert addr >= 0x2000
    assert addr <= 0x23C0
    col = addr % 0x20
    row = (addr - 0x2000 - col) // 0x20
    return row, col


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cell", type=lambda x: tuple(map(int, x.split(","))))
    parser.add_argument("--ppu", type=lambda x: int(x, 0))
    args = parser.parse_args()

    if args.cell:
        cell = args.cell
        ppu = to_ppu(*args.cell)
    elif args.ppu:
        ppu = args.ppu
        cell = from_ppu(args.ppu)
    else:
        parser.print_help()
        return

    print(f"; the cell {cell[0]},{cell[1]} has PPU coordinates 0x{ppu:04X}")


if __name__ == "__main__":
    main()
