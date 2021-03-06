# TODO

As I barely work in this project I have a TODO list here that I update every
now and then. It's probably outdated already.

## Source

- Remove the cc65 dependency by providing an in-house assembler
- Homogeneize the variable and label names
- Rewrite stage.s, it's quite confusing and unstructured
- Visualize the distribution of the code, routines, and variables
- Introduce a general concept of counters for cycle computing
- Explore using objects instead of a monolithic application

## Asset compiler

- Rename the package
- Homogeinize the asset compilers and asset compiled
- Think about a better format for stages rather than yaml
- Use click instead of argparse for all the asset compiler modules
- Update the serialize module to allow for comments in symbols
- Finish the stage designer to be part of the main code

## Gameplay

- Select the stage with a menu
- Add a battery collectible that provides energy
- Add a slow tile that consumes two steps to go into
- Add a box that you can push around
- Add an enemy that moves in a pattern
- Introduce an usage for A and B buttons:
    - Allow to "freeze" one robot for one step by pressing A or B

## Audio

- Add basic sound effects
- Make sound effects have priority over music
- Add some gameplay music
- Add failure jingle
- Add success jingle
- Support famistudio (still not clear what to support)
  - Support all 4 channels
  - Support songs with several patterns
  - Support volume envelopes
  - Support tremolo


## Graphics

- Change PPU rendering to not need the PPU_ENCODED_LEN
- Introduce basic animations for the characters
- Add a title screen
- Populate the area around the playing cells
- Create an asset tiler for big images
- Refactor the chr compiler

## Text

- Change format to have length instead of 0xff as an end character
- Introduce text that appears in the screen letter by letter
