.PHONY: clean all tools

all: ammih.nes

tools: encode translate

clean:
	rm -f chr.s chr.bin prg.bin ammih.nes ammih.dbg *.o encode translate
	rm -rf venv

venv: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

ammih.nes prg.bin: chr.bin ammih.s initialize.s stages.s text.s chr.s input.s rendering.s
	ca65 -g ammih.s
	ld65 --dbgfile ammih.dbg -t nes ammih.o -o ammih.nes

chr.s chr.bin: tiles/chr.conf tiles/*.png venv
	./venv/bin/python tiler.py tiles/chr.conf
