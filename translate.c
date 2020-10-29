#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void exit_with_usage(char *argv[]) {
	fprintf(stderr, "Usage: %s [-p PPUADDR] <x-coordinate> <y-coordinate>\n\nUse -p to provide ppu coordinates instead in hexadecimal\n\n", argv[0]);
	exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
	int opt, x, y, addr;
	char * ppuaddr = NULL;

	while ((opt = getopt(argc, argv, "hp:")) != -1) {
		switch(opt) {
			case 'p':
			    ppuaddr = strdup(optarg);
				break;
			case 'h':
			default:
				exit_with_usage(argv);
		}
	};

	if (ppuaddr != NULL && optind != argc)
		exit_with_usage(argv);
	else if (ppuaddr == NULL && optind + 2 != argc)
		exit_with_usage(argv);

	if (ppuaddr == NULL) {
		x = atoi(argv[optind++]);
		y = atoi(argv[optind++]);
		if (x >= 32) {
			fprintf(stderr, "The coordinate for x is too big! (%d >= 32)\n", x);
			exit(EXIT_FAILURE);
		}
		if (y >= 30) {
			fprintf(stderr, "The coordinate for y is too big! (%d >= 30)\n", y);
			exit(EXIT_FAILURE);
		}
		addr = 0x2000 + x + y * 0x20;
	} else {
		addr = strtol(ppuaddr, NULL, 16);
		if (addr < 0x2000) {
			fprintf(stderr, "The ppu coordinate is too small! ($%04x < $2000)\n", addr);
			exit(EXIT_FAILURE);
		}
		if (addr > 0x23bf) {
			fprintf(stderr, "The ppu coordinate is too big! ($%04x > $23bf)\n", addr);
			exit(EXIT_FAILURE);
		}
		x = addr % 0x20;
		y = (addr - 0x2000 - x) / 0x20;
	}

	printf("; tile (%02d, %02d) == PPU $%04x\n", x, y, addr);

	return 0;
}
