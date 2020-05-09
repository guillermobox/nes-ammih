#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

struct inesheader {
	char head[4];
	char prgsize;
	char chrsize;
	char flagslower;
	char flagsupper;
	char ignored[3];
	char padding[5];
};

void insert_file(const char *path, size_t expected_size, size_t offset, FILE *dst)
{
	char data[expected_size];
	struct stat st;
	if (stat(path, &st) != 0) {
		printf("Impossible to read file '%s'\n", path);
		exit(1);
	}
	if (st.st_size != expected_size) {
		printf("Size of file '%s' should be: 0x%x (%ld bytes) instead is: 0x%x (%ld bytes)\n", path, expected_size, expected_size, st.st_size, st.st_size);
		exit(1);
	}
	FILE * f = fopen(path, "rb");
	fread(data, expected_size, 1, f);
	fclose(f);
	fwrite(data + offset, expected_size - offset, 1, dst);
};

int main(int argc, char *argv[])
{
	char *output = NULL;
	char *prg = NULL;
	char *chr = NULL;
	int opt;
        while ((opt = getopt(argc, argv, "c:p:o:")) != -1) {
		switch(opt) {
			case 'o':
				output = strdup(optarg);
				break;
			case 'p':
				prg = strdup(optarg);
				break;
			case 'c':
				chr = strdup(optarg);
				break;
		}
	}

	struct inesheader header;
	memset(&header, 0, sizeof(struct inesheader));
	header.head[0] = 0x4E;
	header.head[1] = 0x45;
	header.head[2] = 0x53;
	header.head[3] = 0x1A;
	header.prgsize = 2;
	header.chrsize = 1;

	FILE * f = fopen(output, "wb");
	fwrite(&header, sizeof(header), 1, f);
	insert_file(prg, 0x8010, 0x10, f);
	insert_file(chr, 0x2000, 0x00, f);
	fclose(f);
}
