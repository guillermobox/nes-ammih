from dataclasses import dataclass
import io
import struct
import sys
import yaml

from .translate import to_ppu
from .serialize import print_address_table, print_data, print_symbols


def encode_char(ch):
    if ch == " ":
        return 0x24
    elif ch.isdigit():
        return ord(ch) - ord("0")
    elif ch.isalpha():
        return ord(ch) - ord("a") + 0x0A


@dataclass
class Message:
    name: str
    text: str
    row: int
    col: int = "centered"

    @property
    def coordinates(self):
        if self.col == "centered":
            col = 16 - len(self.text) // 2
            return self.row, col
        return self.row, self.col

    @property
    def payload(self):
        loc = self.coordinates
        ppu_address = to_ppu(loc[0], loc[1])
        payload = struct.pack(">h", ppu_address)
        payload += bytes(encode_char(c) for c in self.text)
        payload += b"\xff"
        return payload


def main():
    addrs = {}
    data = yaml.safe_load(open(sys.argv[1], "r").read())
    msgs = [Message(**row) for row in data]
    for msg in msgs:
        addrs[msg.name] = msg
        print_data(msg.name, msg.payload)

    symbols = [msg.name for msg in addrs.values()]
    print_address_table("MESSAGES_TABLE", symbols)

    symbols = {f"MSG_{msg.name.upper()}": 2 * i for i, msg in enumerate(addrs.values())}
    print_symbols(symbols)


if __name__ == "__main__":
    main()
