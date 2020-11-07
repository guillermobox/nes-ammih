def to_ac65(data, width=8):
    ret = ""
    while data:
        ret += ".byte " + ",".join(f"${x:02X}" for x in data[0:width]) + "\n"
        data = data[width:]
    return ret
