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
    location: str

    @property
    def ppu_location(self):
        m = re.match(r'([0-9]+) ([0-9]+)', self.location)
        if m is not None:
            return int(m.group(1)), int(m.group(2))
        m = re.match(r'center ([0-9]+)', self.location)
        if m is not None:
            x = 16 - len(self.text) // 2
            y = int(m.group(1))
            return x, y


addrs = {}
data = yaml.safe_load(open('message.yaml', 'r').read())
msgs = [Message(**row) for row in data]
for msg in msgs:
    addrs[msg.name] = msg
    print(f"{msg.name}:")

    loc = msg.ppu_location
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
    line.append(symbols.pop())
    if sum(map(len, line)) > 30:
        print(f".addr {','.join(line)}")
        line = []
if line:
    print(f".addr {','.join(line)}")
print()

maxlen = max(map(len, addrs.keys()))
for i, msg in enumerate(addrs.values()):
    print(f'MSG_{msg.name.upper():{maxlen}} = {2*i} ; {msg.text} @ {msg.location}')