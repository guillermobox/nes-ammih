.PHONY: clean purge all tools toolchains

all: ammih.nes

tools: encode translate
toolchains: cc65 venv

cc65:
	git clone https://github.com/cc65/cc65.git
	cd cc65/src && make ../bin/ca65 ../bin/ld65

clean:
	rm -f chr.s chr.bin prg.bin ammih.nes ammih.dbg *.o encode translate

purge: clean
	rm -rf venv cc65

venv: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

ammih.nes prg.bin: cc65 chr.bin ammih.s initialize.s stages.s text.s chr.s input.s rendering.s version.s audio.s
	cc65/bin/ca65 -g ammih.s
	cc65/bin/ld65 --dbgfile ammih.dbg --config cc65/cfg/nes.cfg ammih.o -o ammih.nes

chr.s chr.bin: tiles/chr.conf tiles/*.png venv
	./venv/bin/python tiler.py tiles/chr.conf

#version.s: encode
#	git rev-parse --short HEAD | ./encode > version.s
