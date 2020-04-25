.PHONY: clean all tools

all: ammih.nes

tools: assemble encode

clean:
	rm -f chr.s chr.bin prg.bin ammih.nes *.o assemble encode

ammih.nes: prg.bin chr.bin assemble
	./assemble -p prg.bin -c chr.bin -o ammih.nes

prg.bin: ammih.s ammih.cfg initialize.s stages.s text.s
	cl65 --config ammih.cfg ammih.s -o prg.bin

chr.s chr.bin: tiles/*.png
	python tiler.py tiles/font.png @solid tiles/robot.png@column tiles/terminal.png tiles/ground.png tiles/batteryfull.png tiles/floor.png tiles/box.png
