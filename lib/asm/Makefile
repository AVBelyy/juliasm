CC = gcc
ASM = yasm
AR = ar
CC_OPTS = -Wall -Wextra -std=c99 -m64 -O2 -L. -I include
ASM_OPTS = -f elf64 -g dwarf2

all: libjulia.o

clean:
	rm -f libjulia.o

libjulia.o: libjulia.asm
	$(ASM) -o $@ $(ASM_OPTS) $^

