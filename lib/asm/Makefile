ASM_OPTS = -g dwarf2 -f elf64

all: libjulia.a

clean:
	rm -f *.o
	rm -f libjulia.a

libjulia.a: libjulia.o
	ar rcs $@ $<

libjulia.o: libjulia.asm
	yasm -o $@ $(ASM_OPTS) $^
