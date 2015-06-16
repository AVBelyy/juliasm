default     rel
    

section .data

ONED:       dd  1.0
TWOD:       dd  2.0 


section    .text

    global  juliaGeneratePart

        struc   Image
a:          resd    1
b:          resd    1
scale:      resd    1
maxn:       resd    1
    	endstruc

juliaGeneratePart: 
            push    r12
            push    rbx
            push    r13
            push    r14
            push    r15
            mov     rax, rdi        ;; rax = Image

            mov     r12, rsi        ;; r12 = out

            mov     rbx, rdx        ;; rbx = x1
            mov     r13, rcx        ;; r13 = y1
            mov     r14, r8         ;; r14 = x2
            mov     r15, r9         ;; r15 = y2

            mov     r8, r13         ;; r8 = y1
            mov     r10, r15        ;; r10 = y2

            xorps  xmm8, xmm8
            movss  xmm8, [rax + a]             

            xorps  xmm9, xmm9
            movss  xmm9, [rax + b]
            
            xorps   xmm10, xmm10
            movss   xmm10, [rax + scale]       ;;xmm10 - scale

            xorps    xmm6, xmm6
            xor      rcx, rcx
            mov      ecx, [rax + maxn]
            mov      rdx, rcx
            cvtsi2ss xmm6, rcx

            push    rax

            xorps  xmm14, xmm14
            movss   xmm14,  [TWOD]               ;; YMM14 = TWO

            ;; R = (1 + sqrt(1 + 4*|c|))/2
            movaps  xmm5, xmm8
            mulps   xmm5, xmm8
            movaps  xmm2, xmm9
            mulps   xmm2, xmm9
            addps   xmm5, xmm2
            mulps   xmm5, xmm14
            mulps   xmm5, xmm14
            movss   xmm15, [ONED]
            addps   xmm5, xmm15
            sqrtps  xmm5, xmm5
            addps   xmm5, xmm15
            divps   xmm5, xmm14

            mov     rax, 255
            cvtsi2ss xmm7, rax

.loop_h:
            mov     r9, rbx         ;; r9 = x1
            mov     r11, r14        ;; r11 = x2

.loop_w:    cvtsi2ss    xmm0, r8
            mulps       xmm0, xmm10
            
            cvtsi2ss    xmm1, r9
            mulps   xmm1, xmm10

            xor     rcx, rcx

.loop_n:    movaps  xmm2, xmm0
            mulps   xmm2, xmm0            ;; YMM2 = a*a - b*b + A (see c++ code)
            movaps  xmm3, xmm1
            mulps   xmm3, xmm1
            subps   xmm2, xmm3          
            addps   xmm2, xmm8      

            movaps  xmm3, xmm0
            mulps   xmm3, xmm1            ;; YMM3 = 2*a*b + B (see c++ code)
            mulps   xmm3, xmm14
            addps   xmm3, xmm9

            movaps  xmm0, xmm2                  ;; a = YMM2
            movaps  xmm1, xmm3                  ;; b = YMM3

            inc     rcx

            mulps   xmm2, xmm2          
            mulps   xmm3, xmm3
            addps   xmm2, xmm3
            sqrtps  xmm2, xmm2
            comiss  xmm2, xmm5           ;; if Rn < R then +1 to N else +0 to N
            jnb      .stop_n
            cmp     rcx, rdx
            jl      .loop_n

.stop_n     
            movaps      xmm4, xmm2

            ;; K = (MAXN - N)/MAXN
            cvtsi2ss    xmm2, rcx
            movaps      xmm3, xmm6
            subps       xmm3, xmm2
            divps       xmm3, xmm6

            movaps      xmm2, xmm15
            subps       xmm2, xmm3

            ;; R = 255 * K 
            mulps       xmm3, xmm7

            ;; G = 255 * (1 - K)
            mulps       xmm2, xmm7

            ;; B = 255 * (|Z| > R? 1 : |Z|/R)
            movss       xmm11, xmm15
            comiss      xmm4, xmm5
            jb          .gen_color
            movaps      xmm11, xmm4
            divps       xmm11, xmm5
.gen_color  mulps       xmm11, xmm7
            cvtss2si    rcx, xmm2
            shl         rcx, 8
            cvtss2si    rax, xmm3
            add         rcx, rax
            shl         rcx, 8
            cvtss2si    rax, xmm11
            add         rcx, rax
            
            mov     [r12], ecx                 ;; store colors to memory
            lea     r12, [r12 + 4]

            inc     r9
            cmp     r9, r11
            jl     .loop_w

            inc     r8
            cmp     r8, r10
            jl     .loop_h

            pop     rax
            pop     r15
            pop     r14
            pop     r13
            pop     rbx
            pop     r12
            ret
