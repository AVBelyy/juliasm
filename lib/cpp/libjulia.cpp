#include <libjulia.h>
#include <math.h>

const int MAXN = 50;
const int BLACK = 0;
const int WHITE = 16777215;

const float A = 1.17;
const float B = 0.0022;

Image * juliaGenerateImage(uint32_t w, uint32_t h) {
   Image* image = new Image();
   image->pixels = new Pixel[w*h];
   image->w = w;
   image->h = h;

   for (int i = 0; i < w; i++) {
       for (int j = 0; j < h; j++) {
           float a = i - w/2;
           float b = j - h/2;
           float R = (1+sqrt(a*a+b*b))/2;
           int N = 0;
           for (int k = 1; k <= MAXN; k++) {
                float aNew = a*a-b*b + A;
                float bNew = 2*a*b + B;
                N++;
                if (sqrt(aNew*aNew + bNew*bNew) > R) {
                    break;
                }
                a = aNew;
                b = bNew;
           }
           image->pixels[i*h+j] = (uint32_t)WHITE*(((double)N)/MAXN);
       }
   }
   return image;
}
