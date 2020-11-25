import sys


def print_address_table(label, addresses, linewidth=30):
    print(f"{label}:")
    line = []
    for address in addresses:
        line.append(address)
        if sum(map(len, line)) > linewidth:
            print(f".addr {','.join(line)}")
            line = []
    if line:
        print(f".addr {','.join(line)}")
    print()


def print_data(label, data, width=8):
    print(f"{label}:")
    while data:
        print(".byte " + ",".join(f"${x:02X}" for x in data[0:width]))
        data = data[width:]
    print()


def print_symbols(symbols, file=sys.stdout):
    maxlen = max(map(len, symbols.keys()))
    for symbol, value in symbols.items():
        print(f"{symbol:{maxlen}} = ${value:02x}", file=file)
