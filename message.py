from dataclasses import dataclass
import io
import re
import subprocess
import yaml


def to_ac65(data, width=8):
    ret = ''
    while data:
        ret += '.byte ' + ','.join(f'${x:02X}' for x in data[0:width]) + '\n'
        data = data[width:]
    return ret


@dataclass
class Message:
    name: str
    text: str
    row: int
    col: int = 'centered'

    @property
    def coordinates(self):
        if self.col == 'centered':
            col = 16 - len(self.text) // 2
            return self.row, col
        return self.row, self.col


addrs = {}
data = yaml.safe_load(open('message.yaml', 'r').read())
msgs = [Message(**row) for row in data]
for msg in msgs:
    addrs[msg.name] = msg
    print(f"{msg.name}:")

    loc = msg.coordinates
    p = subprocess.run(['./translate', str(loc[0]), str(loc[1])], capture_output=True)
    if p.returncode == 0:
        print(to_ac65(p.stdout), end='')

    p = subprocess.run(['./encode'], input=msg.text.encode('ascii'), capture_output=True)
    if p.returncode == 0:
        print(to_ac65(p.stdout + b'\xff'), end='')
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
    print(f'MSG_{msg.name.upper():{maxlen}} = {2*i} ; {msg.text} @ {msg.row} {msg.col}')