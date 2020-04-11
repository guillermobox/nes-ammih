.PHONY: clean all tools

all: ammih.nes

tools: assemble encode

clean:
	rm -f prg.bin *.nes *.o assemble encode

ammih.nes: prg.bin chr.bin assemble
	./assemble -p prg.bin -c chr.bin -o ammih.nes

prg.bin: ammih.s ammih.cfg
	cl65 --config ammih.cfg ammih.s -o prg.bin
