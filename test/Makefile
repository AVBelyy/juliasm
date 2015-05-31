CC = gcc
ASM = yasm
AR = ar
CC_OPTS = -Wall -Wextra -std=c99 -m64 -O2 -L. -I../lib/include
ASM_OPTS = -f elf64 -g dwarf2

all: dumptopng

clean:
	rm -f dumptopng
	rm -f dumptopng.o
	rm -f libjulia.a
	rm -f libjulia.o

dumptopng: libjulia.a dumptopng.o 	
	$(CC) -o $@ $(CC_OPTS) 'Magic++-config --ldflags --libs' tester.o -ljulia

dumptopng.o: dumptopng.cpp
	$(CC) -o $@ $(CC_OPTS)  'Magic++-config --cppflags --cxxflags' -c  $<

libjulia.a: libjulia.o
	$(AR) rcs $@ $<

libjulia.o: libjulia.asm
	$(ASM) -o $@ $(ASM_OPTS) $^

