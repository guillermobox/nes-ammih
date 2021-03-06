from pprint import pprint
from typing import List, Mapping
from dataclasses import dataclass, field, asdict
import re
import sys


@dataclass
class Envelope:
    type: str
    length: int
    values: List[int]


@dataclass
class Instrument:
    name: str
    envelopes: List[Envelope] = field(default_factory=list)


@dataclass
class Note:
    time: int
    value: str
    instrument: str

    lookup = "C C# D D# E F F# G G# A A# B".split()

    def bytes(self):
        yield self.time
        if self.value == "Stop":
            offset = 255
        else:
            octave = int(self.value[-1]) - 1
            note = int(Note.lookup.index(self.value[:-1]))
            offset = octave * len(Note.lookup) + note + 3
        yield offset


@dataclass
class PatternInstance:
    time: int
    pattern: str


@dataclass
class Channel:
    patterns: Mapping[str, Note] = field(default_factory=dict)
    instances: List[PatternInstance] = field(default_factory=list)


@dataclass
class Song:
    name: str
    length: int
    square1: Channel = Channel()
    square2: Channel = Channel()
    triangle: Channel = Channel()
    noise: Channel = Channel()


@dataclass
class Project:
    name: str
    author: str
    instruments: Mapping[str, Instrument] = field(default_factory=dict)
    songs: Mapping[str, Song] = field(default_factory=dict)


class FamiStudioParser:
    name_regexp = re.compile(r"\s*(?P<name>[^\s]+)")
    attribute_regexp = re.compile(r"(?P<attribute>[^=\s]+)=\"(?P<value>[^\"]+)\"")

    @staticmethod
    def _tokenizer(line):
        name = re.match(FamiStudioParser.name_regexp, line)
        line = line[name.span("name")[1] :]
        matches = re.finditer(FamiStudioParser.attribute_regexp, line)
        return (
            name["name"].lower(),
            {m["attribute"].lower(): m["value"] for m in matches},
        )

    def parse(self, filename):
        for line in open(filename, "r"):
            name, attributes = self._tokenizer(line)
            self._handle_dispatcher(name, attributes)

    def _handle_dispatcher(self, name, attributes):
        handle_method = f"handle_{name.lower()}"
        method = getattr(self, handle_method, None)
        if method:
            method(**attributes)

    def handle_project(self, name, author, **kwargs):
        self.project = Project(name=name, author=author)

    def handle_instrument(self, name):
        self.active_instrument = Instrument(name=name)
        self.project.instruments[name] = self.active_instrument

    def handle_envelope(self, type, length, values):
        self.active_envelope = Envelope(
            type=type, length=int(length), values=[int(values)]
        )
        self.active_instrument.envelopes.append(self.active_envelope)

    def handle_song(self, name, length, **kwargs):
        self.active_song = Song(name=name, length=int(length))
        self.project.songs[name] = self.active_song

    def handle_channel(self, type):
        if type == "Square1":
            self.active_channel = self.active_song.square1
        if type == "Square2":
            self.active_channel = self.active_song.square2
        if type == "Triangle":
            self.active_channel = self.active_song.triangle
        if type == "Noise":
            self.active_channel = self.active_song.noise

    def handle_pattern(self, name):
        self.active_pattern = []
        self.active_channel.patterns[name] = self.active_pattern

    def handle_note(self, time, value, instrument=None):
        self.active_pattern.append(
            Note(time=int(time), value=value, instrument=instrument)
        )

    def handle_patterninstance(self, time, pattern):
        self.active_channel.instances.append(
            PatternInstance(time=int(time), pattern=pattern)
        )


def main():
    parser = FamiStudioParser()
    parser.parse(sys.argv[1])
    for song in parser.project.songs.values():
        for name, pattern in song.square1.patterns.items():
            print(f"{song.name} Square {name}:".replace(" ", "_"))
            data = [b for note in pattern for b in note.bytes()]
            while data:
                print(f".byte " + ",".join(f"${x:02X}" for x in data[0:16]))
                data = data[16:]
            print(".byte $FF")
        for name, pattern in song.triangle.patterns.items():
            print(f"{song.name} Triangle {name}:".replace(" ", "_"))
            data = [b for note in pattern for b in note.bytes()]
            while data:
                print(f".byte " + ",".join(f"${x:02X}" for x in data[0:16]))
                data = data[16:]
            print(".byte $FF")

    for song in parser.project.songs.values():
        print("; square pattern instances")
        for pattern in song.square1.instances:
            print(pattern.time, pattern.pattern)

        for pattern in song.triangle.instances:
            print(pattern.time, pattern.pattern)


if __name__ == "__main__":
    main()
