#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

void exit_with_usage(char *argv[]) {
	fprintf(stderr, "Usage: %s <x-coordinate> <y-coordinate>\n", argv[0]);
	exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
	int opt, x, y, addr;

	while ((opt = getopt(argc, argv, "h")) != -1) {
		switch(opt) {
			case 'h':
			default:
				exit_with_usage(argv);
		}
	};

	if (optind + 1 >= argc) {
		exit_with_usage(argv);
	};

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

	printf("; input tile coordinates: x = %d y = %d\n", x, y);
	printf("; PPU nametable address: 0x%04x\n", addr);


	return 0;
}
