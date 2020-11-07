from dataclasses import dataclass
import io
import re
import subprocess
import struct
import sys
import yaml

from asset_compiler.translate import to_ppu
from asset_compiler.serialize import to_ac65


def encode_char(ch):
    if ch == ' ':
        return b'\x24'
    elif ch.isdigit():
        return bytes([ord(ch) - ord('0')])
    elif ch.isalpha():
        return bytes([(ord(ch) - ord('a')) + 0x0a])


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
        loc = msg.coordinates
        ppu_address = to_ppu(loc[0], loc[1])
        payload = struct.pack(">h", ppu_address)
        payload += b''.join(encode_char(c) for c in msg.text)
        payload += b'\xff'
        return payload


addrs = {}
data = yaml.safe_load(open(sys.argv[1], "r").read())
msgs = [Message(**row) for row in data]
for msg in msgs:
    addrs[msg.name] = msg
    print(f"{msg.name}:")
    print(to_ac65(msg.payload), end="")
    print()

print("MESSAGES_TABLE:")

symbols = [msg.name for msg in addrs.values()]
line = []
while symbols:
    line.append(symbols.pop(0))
    if sum(map(len, line)) > 30:
        print(f".addr {','.join(line)}")
        line = []
if line:
    print(f".addr {','.join(line)}")
print()

maxlen = max(map(len, addrs.keys()))
for i, msg in enumerate(addrs.values()):
    print(f"MSG_{msg.name.upper():{maxlen}} = {2*i} ; {msg.text} @ {msg.row} {msg.col}")
