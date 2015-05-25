#include <libjulia.h>
#include <math.h>

const int MAXN = 50;
const int BLACK = 0;
const int WHITE = 16777215;

Image * juliaGenerateImage(int32_t w, int32_t h) {
   Image* image = new Image();
   image->pixels = new Color[w*h];
   image->w = w;
   image->h = h;

   for (int i = 0; i < w; i++) {
       for (int j = 0; j < h; j++) {
           int a = i - w/2;
           int b = j - h/2;
           double R = (1+sqrt(a*a+b*b))/2;
           int N = 0;
           for (int k = 1; k <= MAXN; k++) {
                int aNew = a*a-b*b;
                int bNew = 2*a*b;
                N++;
                if (sqrt(aNew*aNew + bNew*bNew) > R) {
                    break;
                }
                a = aNew;
                b = bNew;
           }
           image->pixels[i*w+j] = (int)WHITE*(((double)N)/MAXN);
       }
   }
   return image;
}

int main() {
    Image* julia = juliaGenerateImage(5000, 5000);
}
