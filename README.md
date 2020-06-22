# A Match Made In Heaven

This is a basic puzzle-like NES game. [You can try the game with a js emulator](http://guillermobox.github.io/demo/).

The shipped makefile has two toolchains that deal with the compiling of the game (using  [cc65](https://github.com/cc65/cc65.git), requires a C compiler) and also a python application to assemble the assets (requires python3). Both toolchains are setup with the first `make` invokation. This way just running `make` produces `ammih.nes`.

## The game

This is a puzzle game consisting on two characters that move synchronously. On each stage there are exit locations, and the objective is to put both characters at the same time in those locations.

## Gameplay

Just use the arrows to move both characters around.
