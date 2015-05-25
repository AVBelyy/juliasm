#ifndef _LIBJULIA_HEADER
#define _LIBJULIA_HEADER
#include <libimage.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

Image * juliaGenerateImage(uint32_t w, uint32_t h);

#ifdef __cplusplus
}
#endif

#endif
