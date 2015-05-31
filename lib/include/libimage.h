#ifndef _LIBIMAGE_HEADER
#define _LIBIMAGE_HEADER
#include <stdint.h>

typedef uint32_t Pixel;
struct Image {
    uint32_t w;
    uint32_t h;
    Pixel * pixels;
};

#ifdef __cplusplus
extern "C" {
#endif

Image * imageGetPart(uint32_t w, uint32_t h);

#ifdef __cplusplus
}
#endif

#endif
