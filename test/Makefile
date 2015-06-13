CXXFLAGS = -g -m64 -I../lib/include
LDFLAGS = -L../lib/cpp -ljulia

all: dumptopng

clean:
	rm -f *.o
	rm -f dumptopng

dumptopng: dumptopng.o
	g++ -o $@ $< `Magick++-config --ldflags --libs` $(LDFLAGS)

dumptopng.o: dumptopng.cpp
	g++ -o $@ -O2 $(CXXFLAGS) `Magick++-config --cppflags --cxxflags` -c $<
