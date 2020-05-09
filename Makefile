.PHONY: clean all tools

all: ammih.nes

tools: assemble encode translate

clean:
	rm -f chr.s chr.bin prg.bin ammih.nes *.o assemble encode translate

ammih.nes: prg.bin chr.bin assemble
	./assemble -p prg.bin -c chr.bin -o ammih.nes

prg.bin: ammih.s ammih.cfg initialize.s stages.s text.s chr.s input.s rendering.s
	cl65 --config ammih.cfg ammih.s -o prg.bin

chr.s chr.bin: tiles/chr.conf tiles/*.png
	python tiler.py tiles/chr.conf
