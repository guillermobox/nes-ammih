.PHONY: clean purge all toolchains

all: ammih.nes

toolchains: cc65 venv

cc65:
	git clone https://github.com/cc65/cc65.git
	cd cc65/src && make ../bin/ca65 ../bin/ld65

clean:
	rm -f chr.s chr.bin prg.bin ammih.nes ammih.dbg *.o
	rm -f message.s stages_data.s

purge: clean
	rm -rf venv cc65

venv:
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

ammih.nes prg.bin: cc65 chr.bin ammih.s initialize.s stages.s text.s chr.s input.s rendering.s audio.s message.s stages_data.s
	cc65/bin/ca65 -g ammih.s
	cc65/bin/ld65 --dbgfile ammih.dbg --config cc65/cfg/nes.cfg ammih.o -o ammih.nes

chr.s chr.bin: tiles/chr.conf tiles/*.png venv
	venv/bin/python -m asset_compiler.tiler tiles/chr.conf

message.s: venv message.yaml
	venv/bin/python -m asset_compiler.message message.yaml > message.s

stages_data.s: venv stages.yaml
	venv/bin/python -m asset_compiler.stage stages.yaml > stages_data.s
