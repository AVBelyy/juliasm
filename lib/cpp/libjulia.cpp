#include <libjulia.h>
#include <math.h>
#include <stdio.h>
#include <cstdlib>

const int MAXN = 2000;
const int BLACK = 0;
const int WHITE = 0xffffff;

const float A = 0.28;
const float B = 0.0113;
const float scale = 0.002;


int getBinaryColor(int N, int MAXN) {
    if (N == MAXN) {
        return 0xff0000;
    }
    return 0xffffff;
}

int getGradientColor(int N, int MAXN) {
    return (int)((((double)MAXN-N+1)/MAXN)*WHITE);
}

Image * juliaGenerateImage(uint32_t w, uint32_t h) {
   Image* image = new Image();
   image->pixels = new Pixel[w*h];
   image->w = w;
   image->h = h;

    float R = (1+sqrt(1 + A*A+B*B))/2;

   for (int i = 0; i < h; i++) {
       for (int j = 0; j < w; j++) {
            float a = scale*(j - (int) w/2);
            float b = scale*(i - (int) h/2);
          
            int N = 0;
            for (int k = 1; k <= MAXN; k++) {
                float aNew = a*a-b*b + A;
                float bNew = 2.0f*a*b + B;
                N++;
                if (sqrt(aNew*aNew + bNew*bNew) > R) {
                    break;
                }
                a = aNew;
                b = bNew;
            }
            image->pixels[i*w+j] = getGradientColor(N, MAXN);
       }
   }
   return image;
}

/*int main(int argc, char* argv[]) {
    Image* a = juliaGenerateImage(1024,768);
    return 0;
}*/
