#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

void validate_string(char *input)
{
	int c;
	while (*input) {
		c = tolower(*input++);
		if (c == ' ' || isalpha(c) || isdigit(c))
			continue;
		fprintf(stderr, "Character: '%c' (%d) is not supported\n", c, c);
		exit(1);
	};
}

int main(int argc, char *argv[])
{
	ssize_t read;
	size_t size = 0;
	char *input = NULL;

	read = getline(&input, &size, stdin);
	if (read < 0) {
		fprintf(stderr, "Error reading input\n");
		exit(1);
	};
	while (isspace(input[read - 1])) {
		input[read - 1] = '\0';
		read--;
	};

	validate_string(input);

	while (*input) {
		char output;
		if (*input == ' ')
			output = 0x24;
		else if (isalpha(*input))
			output = (tolower(*input) - 'a') + 0x0a;
		else if (isdigit(*input))
			output = ((*input) - '0');
		fwrite(&output, 1, 1, stdout);
		input++;
	};
	return 0;
}
