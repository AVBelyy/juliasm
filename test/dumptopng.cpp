#include <libjulia.h>
#include <math.h>
#include <Magick++.h> 
#include <iostream>
#include <cstdio>

// Creates julia image of specified WIDTH and HEIGHT
// And outputs it to PNG image.

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
    Image * juliaImage = juliaNewImage(width, height, a, b, scale);
    
    for (int i = 0; i < width; i++ ) {
        juliaGeneratePart(juliaImage, i, 0, i+1, height);
    }
     //   juliaGeneratePart(juliaImage, 200, 200, 500, 500);
 //   juliaGeneratePart(juliaImage, 500, 500, width, height);
 //   juliaGeneratePart(juliaImage, 200, 0, 500, 200); 

    // Draw test image (ellipsis)
   Pixel * pixels = new Pixel[width * height];
  /*  for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int64_t y = i - height / 2;
            int64_t x = j - width / 2;
            uint32_t color = (uint32_t) (sin(0.1f * i + 0.1 * j) * 0xffffff);
            uint32_t c = 200;
            pixels[i * width + j] = (x * x + y * y) * (x * x + y * y) <= 2 * c * c * (x * x - y * y) && (y < x || y < -x) ? color : 0;
        }
    }
    */    
    // Output it via ImageMagick
    Magick::InitializeMagick(argv[0]);
    Magick::Image magickImage(width, height, "BGRP", Magick::CharPixel, (void *) juliaImage->pixels);
    //Magick::Image magickImage(width, height, "BGRP", Magick::CharPixel, (void *) pixels);

    magickImage.write(filename);

    return 0;
}
