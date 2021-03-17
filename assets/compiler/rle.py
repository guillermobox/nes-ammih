def rle(values):
    values = list(values)
    if not values:
        return []
    count = 1
    value = values.pop(0)
    while values:
        next = values.pop(0)
        if value != next or count == 255:
            yield count
            yield value
            value = next
            count = 1
        else:
            count += 1
    yield count
    yield value
