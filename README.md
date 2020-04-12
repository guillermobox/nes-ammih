# A Match Made In Heaven

This is a basic puzzle-like NES game.

To compile, the cc65 suite should be installed, then just `make`, the result is
`ammih.nes`.

## The game

Is still using sprites from Super Mario Bros, and no sound. A very basic
gameplay is already implemented. This is a bare minimum from which new
mechanics should be easy to implement, as the idea is to be flexible
with regards to the future mechanics.

Similarly, audio and image features are still not decided, so the global
look-and-feel of the game is yet to determine.

## Gameplay

Use the arrows to move both characters around. They can only move inside the
white area. The objective is to put both in the orange squares.

## Todo

A few ideas that I will introduce soon:
  - A deadly square that kills the character
  - A box that can be pushed over, if there is enough space
  - An enemy that kills the character, moves around in a simple fixed pattern

A tool to easily create and edit the levels, from the command line or a gui.
