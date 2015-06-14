#ifndef _LIBIMAGE_HEADER
#define _LIBIMAGE_HEADER
#include <stdint.h>

typedef uint32_t Pixel;
struct Image {
    uint64_t w;
    uint64_t h;
    Pixel * pixels;
    float a, b, scale;
};

#endif
