from dataclasses import dataclass, field
import sys
import yaml

from .serialize import print_address_table, print_data, print_symbols


@dataclass
class Stage:
    entry: list
    exit: list
    walkable: list
    steps: int
    dead: list = field(default_factory=list)

    def payload(self):
        rv = b""
        rv += bytes([len(self.walkable)] + self.walkable)
        rv += bytes([len(self.dead)] + self.dead)
        rv += bytes(self.entry)
        rv += bytes(self.exit)
        rv += bytes([self.steps])
        return rv


def main():
    with open(sys.argv[1], "r") as fh:
        data = yaml.safe_load(fh)

    stages = [Stage(**stage) for stage in data]
    addrs = [f"stage_{n:03}" for n, _ in enumerate(stages)]

    print_data("numberOfStages", [len(stages)])
    print_address_table("stagesLookUpTable", addrs)

    for addr, stage in zip(addrs, stages):
        print_data(addr, stage.payload())


if __name__ == "__main__":
    main()
