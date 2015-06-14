
    
section .data


ONED:       dd  1.0
TWOD:       dd  2.0 
TWO:        dq  2

WHITE:      dd  0x0000ff
BLACK:      dd  0


        ;;  c = A + i*B  
A:          dd      -0.8
B:          dd      0.156
SCALE:      dd      0.004
MAXN:       dd      500


section    .text

    extern  malloc
    extern  free

    global  juliaGeneratePart
    global  juliaNewImage

        struc   Image
w:          resq    1
h:          resq    1
pixels:     resq    1
a:          resd    1
b:          resd    1
scale:      resd    1
    	endstruc

juliaGeneratePart: 
            ;syspush
            push    r12
            push    rbx
            push    r13
            push    r14
            push    r15
            ;;call    newImage
            mov     rax, rdi        ;; rax = Image
            mov     rbx, rsi
            mov     r13, rdx
            mov     r14, rcx
            mov     r15, r8

            mov     r12, [rax + pixels]
            mov     rdi, [rax + w]
            mov     rsi, [rax + h]

            mov     rcx, rsi
            shr     rcx, 1
            mov     r8, r13
            sub     r8, rcx         ;; r8 = y1 - h/2
            mov     r10, r15
            sub     r10, rcx        ;; r10 = y2 - h/2 

            mov     rsi, [rax + w]
            add     rsi, rbx
            sub     rsi, r14
            inc     rsi
            shl     rsi, 2  ;; rsi = shift = 4 * (w - (x2-x1) + 1)

            xorps  xmm8, xmm8
            movss  xmm8, [rax + a]             

            xorps  xmm9, xmm9
            movss  xmm9, [rax + b]
            
            xorps   xmm10, xmm10
            movss   xmm10, [rax + scale]       ;;xmm10 - scale

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
            divps   xmm5, xmm14          ;; YMM5 = R
            shufps  xmm5, xmm5, 0

            xor     rax, rax
            mov     eax, [WHITE]
            cvtsi2ss xmm7, rax              ;; xmm7 - WHITE
            
            xorps     xmm6, xmm6
            mov     rcx, [MAXN]
            cvtsi2ss    xmm6, rcx             ;; YMM6 = MAXN

            mov     rdx, [MAXN]
            
       ;     mov     r8, rsi
       ;     shr     r8, 1
       ;     mov     r10, r8
       ;     neg     r8

.loop_h:  
         ;   mov     r9, rdi
         ;   shr     r9, 1
         ;   mov     r11, r9
         ;   neg     r9
            mov     rcx, rdi
            shr     rcx, 1
            mov     r9, rbx
            sub     r9, rcx         ;; r9 = x1 - w/2
            mov     r11, r14    
            sub     r11, rcx        ;; r11 = x2 - w/2

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
            shufps  xmm2, xmm2, 0
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
            
            ;; B = 255 * ( |Z| > R? 1 : |Z|/R)
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
            lea     r12, [r12 + rsi]

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
           ; syspop
            ret

%macro syspush 0
      push  rbx
      push  rbp
      push  r12
      push  r13
      push  r14
      push  r15
%endmacro 

%macro syspop 0
      pop   r15
      pop   r14
      pop   r13
      pop   r12
      pop   rbp
      pop   rbx
%endmacro



alligned_malloc:
            test    rsp, 15
            jz      .malloc
            sub     rsp, 8
            call    malloc
            add     rsp, 8
            ret               
.malloc             call  malloc
            ret


alligned_free:
            test    rsp, 15
            jz      .free
            sub     rsp, 8
            call    free
            add     rsp, 8
            ret               
.free       call    free
            ret

%macro ceil 1
      shr %1, 3
      shl %1, 3
      lea %1, [%1 + 8]
%endmacro





juliaNewImage:   syspush
            push    rdi
            push    rsi
            mov     rdi, Image_size
            call    alligned_malloc
            pop     rsi
            pop     rdi
            mov     [rax + w], rdi
            mov     [rax + h], rsi
            movd    [rax + a], xmm0
            movd    [rax + b], xmm1
            movd    [rax + scale], xmm2
            push    rax
            mov     rax, rdi
            mul     rsi
            mov     rdi, rax
            shl     rdi, 2
            call    alligned_malloc
            pop     rdx
            mov     [rdx + pixels], rax
            mov     rax, rdx
            syspop
            ret
