#ifndef _LIBJULIA_HEADER
#define _LIBJULIA_HEADER
#include <libimage.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

Image * juliaGenerateImage(uint64_t w, uint64_t h, float a, float b, float scale);
void juliaGeneratePart(Image * out, uint64_t x1, uint64_t y1, uint64_t x2, uint64_t y2);

#ifdef __cplusplus
}
#endif

#endif
