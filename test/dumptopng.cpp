#include <libjulia.h>
#include <math.h>
#include <Magick++.h> 
#include <iostream>
#include <cstdio>

// Creates julia image of specified WIDTH and HEIGHT
// And outputs it to image.

using namespace std;

int main(int argc, char * argv[]) {
    if (argc != 4) {
        cout << "Usage: " << argv[0] << " width height path-to-png" << endl;
        return 1; 
    }

    int width, height;
    sscanf(argv[1], "%d", &width); 
    sscanf(argv[2], "%d", &height); 
    char * filename = argv[3];

    float a = -0.8;
    float b = 0.156;
    float scale = 0.001;

    // Draw julia image
    JuliaPart info = {
        width,
        height,
        a,
        b,
        scale
    };
    uint32_t * pixels = new uint32_t[width * height];

    juliaGeneratePart(&info, pixels, 0, 0, width, height / 2);
    juliaGeneratePart(&info, pixels + height / 2 * width, 0, height / 2, width, height);

    // Output it via ImageMagick
    Magick::InitializeMagick(argv[0]);
    Magick::Image magickImage(width, height, "BGRP", Magick::CharPixel, (void *) pixels);

    magickImage.write(filename);

    delete pixels;

    return 0;
}
