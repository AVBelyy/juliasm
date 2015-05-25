#ifndef _LIBIMAGE_HEADER
#define _LIBIMAGE_HEADER
#include <stdint.h>

typedef uint32_t Color;
struct Image {
    uint32_t w;
    uint32_t h;
    Color * pixels;
};

#ifdef __cplusplus
extern "C" {
#endif

Image * imageGetPart(uint32_t w, uint32_t h);

#ifdef __cplusplus
}
#endif

#endif
