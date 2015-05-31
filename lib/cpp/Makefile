CXXFLAGS = -m64 -I../include

all: libjulia.a

clean:
	rm -f *.o
	rm -f libjulia.a

libjulia.a: libjulia.o
	ar rcs $@ $<

libjulia.o: libjulia.cpp
	g++ -o $@ -O2 $(CXXFLAGS) -c $<
