SOURCES := $(wildcard src/*.s)
ASSETS := $(addprefix assets/,chr.bin stages.s chr.s messages.s stages.s)

export PYTHONPATH := $(CURDIR)/assets
PYTHON := venv/bin/python
CA65 := cc65/bin/ca65
LD65 := cc65/bin/ld65

.PHONY: clean purge all tools assets

all: ammih.nes

tools: cc65 venv

cc65:
	git clone https://github.com/cc65/cc65.git
	cd cc65 && git checkout V2.19
	cd cc65/src && make ../bin/ca65 ../bin/ld65

venv:
	python3 -m venv venv
	venv/bin/pip install -r requirements.txt

clean:
	rm -f ammih.nes ammih.dbg src/ammih.o
	rm -f $(ASSETS)

purge: clean
	rm -rf venv cc65

ammih.nes: cc65 $(ASSETS) $(SOURCES)
	$(CA65) --debug-info src/ammih.s --include-dir .
	$(LD65) --dbgfile ammih.dbg --config cc65/cfg/nes.cfg src/ammih.o -o ammih.nes

$(ASSETS): venv

assets/chr.s assets/chr.bin: assets/chr.yaml assets/*.png
	$(PYTHON) -m compiler.chr $<

assets/messages.s: assets/messages.yaml
	$(PYTHON) -m compiler.messages $< > $@

assets/stages.s: assets/stages.yaml
	$(PYTHON) -m compiler.stages $< > $@
