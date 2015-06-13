#ifndef _LIBIMAGE_HEADER
#define _LIBIMAGE_HEADER
#include <stdint.h>

typedef uint32_t Pixel;
struct Image {
    uint64_t w;
    uint64_t h;
    float a, b, scale;
    Pixel * pixels;
};

#endif
