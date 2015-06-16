#ifndef _LIBJULIA_HEADER
#define _LIBJULIA_HEADER
#include <stdint.h>

struct JuliaPart {
    uint64_t w;
    uint64_t h;
    float a;
    float b;
    float scale;
};

#ifdef __cplusplus
extern "C" {
#endif

void juliaGeneratePart(JuliaPart * info, void * out, int64_t x1, int64_t y1, int64_t x2, int64_t y2);

#ifdef __cplusplus
}
#endif

#endif
