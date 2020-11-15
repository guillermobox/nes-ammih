import sys


def to_ac65(data, width=8):
    ret = ""
    while data:
        ret += ".byte " + ",".join(f"${x:02X}" for x in data[0:width]) + "\n"
        data = data[width:]
    return ret


def print_address_table(label, addresses, linewidth=30):
    print(f"{label}:")
    line = []
    addresses = addresses.copy()
    while addresses:
        line.append(addresses.pop(0))
        if sum(map(len, line)) > linewidth:
            print(f".addr {','.join(line)}")
            line = []
    if line:
        print(f".addr {','.join(line)}")
    print()


def print_data(label, data):
    print(f"{label}:\n{to_ac65(data)}")


def print_symbols(symbols, file=sys.stdout):
    maxlen = max(map(len, symbols.keys()))
    for symbol, value in symbols.items():
        print(f"{symbol:{maxlen}} = ${value:02x}", file=file)
