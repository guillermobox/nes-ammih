from dataclasses import dataclass
import io
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
    tile: str = None
    row: int = None


addrs = {}
data = yaml.safe_load(open('message.yaml', 'r').read())
msgs = [Message(**row) for row in data]
for msg in msgs:
    p = subprocess.run(['./encode'], input=msg.text.encode('ascii'), capture_output=True)

    if p.returncode == 0:
        print(f"{msg.name}:")
        print(to_ac65(p.stdout + b'\xff'))
        print()
    addrs[msg.name] = msg

maxlen = max(map(len, addrs.keys()))
for i, msg in enumerate(addrs.values()):
    print(f'TXT_{msg.name.upper():{maxlen}} = {2*i} ; {msg.text}')
