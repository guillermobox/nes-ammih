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
    parser.add_argument("--cell", type=lambda x: map(int, x.split(",")))
    parser.add_argument("--ppu", type=lambda x: int(x, 0))
    args = parser.parse_args()

    if args.cell:
        ppu = to_ppu(*args.cell)
        print(f"The ppu coordinates are: 0x{ppu:04X}")
    if args.ppu:
        row, col = from_ppu(args.ppu)
        print(f"The cell coordinates are: {row},{col}")


if __name__ == "__main__":
    main()
