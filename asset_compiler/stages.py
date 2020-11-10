from dataclasses import dataclass, field
import sys
import yaml

from asset_compiler.serialize import to_ac65


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

    print("numberOfStages:")
    print(f".byte ${len(stages):02X}")
    print()
    print(f"stagesLookUpTable:")
    for n, _ in enumerate(stages):
        print(f".addr stage_{n:03}")
    print()

    for n, stage in enumerate(stages):
        print(f"stage_{n:03}:")
        print(to_ac65(stage.payload()))


if __name__ == "__main__":
    main()
