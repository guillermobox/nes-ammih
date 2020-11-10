# TODO

As I barely work in this project I have a TODO list here that I update every
now and then. It's probably outdated already.

## General

- Remove the cc65 dependency by providing an in-house assembler
- Homogeneize the variable and label names
- Rewrite stage.s, it's quite confusing and unstructured
- Visualize the distribution of the code, routines, and variables
- Finish the stage designer to be part of the main code
- Homogeinize the asset compilers and asset compiled
- Think about a better format for stages rather than yaml
- Change the format for the tiles from configuration to yaml
- Use click instead of argparse for all the asset compiler modules

## Gameplay

- Add a battery collectible that provides energy
- Introduce an usage for A and B buttons:
    - Allow to "freeze" one robot for one step by pressing A or B

## Audio

- Add basic sound effects
- Make sound effects have priority over music

The audio engine is designed around famistudio:

- Support famistudio (still not clear what to support)
    - Support volume envelopes

- Add some gameplay music
- Add failure jingle
- Add success jingle

## Graphics

- Change PPU rendering to not need the PPU_ENCODED_LEN
- Introduce basic animations for the characters
- Add a title screen

## Text

- Change format to have length instead of 0xff as an end character
- Introduce text that appears in the screen letter by letter
