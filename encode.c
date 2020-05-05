#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

void validate_string(char *input)
{
	int c;
	while (*input) {
		c = tolower(*input++);
		if (c == ' ' || isalpha(c))
			continue;
		printf("Character: '%c' (%d) is not supported\n", c, c);
		exit(1);
	};
};

int main(int argc, char *argv)
{
	ssize_t read;
	size_t size = 0;
	char *input = NULL;

	read = getline(&input, &size, stdin);
	if (read < 0) {
		printf("Error reading input\n");
		exit(1);
	};
	while (isspace(input[read - 1])) {
		input[read - 1] = '\0';
		read--;
	};

	validate_string(input);

	printf("; Encoded string produced by encode.c\n");
	printf("; The string: \"%s\"\n", input);
	printf(".byte ");
	while (*input) {
		int val;
		if (*input == ' ')
			val = 0x24;
		else if (isalpha(*input))
			val = (tolower(*input) - 'a') + 0x0a;
		printf("$%02x,", val);
		input++;
	};
	printf("$ff\n");
	return 0;
};
