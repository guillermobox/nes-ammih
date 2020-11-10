SOURCES := $(wildcard src/*.s)
ASSETS := $(addprefix assets/,chr.bin stages.s chr.s messages.s stages.s)

PYTHON := venv/bin/python
.PHONY: clean purge all tools assets

all: ammih.nes

tools: cc65 venv

cc65:
	git clone https://github.com/cc65/cc65.git
	cd cc65/src && make ../bin/ca65 ../bin/ld65

clean:
	rm -f ammih.nes ammih.dbg src/ammih.o
	rm -f $(ASSETS)

purge: clean
	rm -rf venv cc65

venv:
	python3 -m venv venv
	venv/bin/pip install -r requirements.txt

ammih.nes: cc65 $(ASSETS) $(SOURCES)
	cc65/bin/ca65 --debug-info src/ammih.s --include-dir .
	cc65/bin/ld65 --dbgfile ammih.dbg --config cc65/cfg/nes.cfg src/ammih.o -o ammih.nes

$(ASSETS): venv

assets/chr.s assets/chr.bin: assets/chr.conf assets/*.png
	$(PYTHON) -m asset_compiler.tiler $<

assets/messages.s: assets/messages.yaml
	$(PYTHON) -m asset_compiler.message $< > $@

assets/stages.s: assets/stages.yaml
	$(PYTHON) -m asset_compiler.stage $< > $@
