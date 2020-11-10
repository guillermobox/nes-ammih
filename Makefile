.PHONY: clean purge all toolchains assets

all: ammih.nes

toolchains: cc65 venv

cc65:
	git clone https://github.com/cc65/cc65.git
	cd cc65/src && make ../bin/ca65 ../bin/ld65

clean:
	rm -f ammih.nes ammih.dbg src/ammih.o
	rm -f assets/messages.s assets/chr.bin assets/chr.s assets/stages.s

purge: clean
	rm -rf venv cc65

assets: assets/chr.s assets/chr.bin assets/messages.s assets/stages.s

venv:
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

ammih.nes prg.bin: cc65 assets/chr.bin src/ammih.s src/initialize.s assets/stages.s src/text.s assets/chr.s src/input.s src/rendering.s src/audio.s assets/messages.s assets/stages.s
	cc65/bin/ca65 --debug-info src/ammih.s --include-dir .
	cc65/bin/ld65 --dbgfile ammih.dbg --config cc65/cfg/nes.cfg src/ammih.o -o ammih.nes

assets/chr.s assets/chr.bin: assets/chr.conf assets/*.png venv
	venv/bin/python -m asset_compiler.tiler assets/chr.conf

assets/messages.s: venv assets/message.yaml
	venv/bin/python -m asset_compiler.message assets/message.yaml > assets/messages.s

assets/stages.s: venv assets/stages.yaml
	venv/bin/python -m asset_compiler.stage assets/stages.yaml > assets/stages.s
