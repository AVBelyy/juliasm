ASM_OPTS = -g dwarf2 -f elf64

all: libjulia.so

clean:
	rm -f *.o
	rm -f libjulia.so

libjulia.so: libjulia.o
	ld -shared -o $@ $^

libjulia.o: libjulia.asm
	yasm -o $@ $(ASM_OPTS) $^
