
    
section .data


REZ_START:  dd  0.0,1.0,2.0,3.0
REZ_SHIFT:  dd  8.0,8.0,8.0,8.0
ONE:        dd  1.0,1.0,1.0,1.0
ONED:       dd  1,1,1,1
TWO:        dd  2.0,2.0,2.0,2.0  
MINUSONE:   dd  1,1,1,1

WHITE:      dd  0xffffff, 0xffffff, 0xffffff, 0xffffff
BLACK:      dd  0,0,0,0
WHITE2:     dd  100000


; TODO : malloc
BUFFER32:   resd    1
        ;;  c = A + i*B  
A:          dd      0.28
B:          dd      0.0113
SCALE:      dd      0.001
MAXN:       dd      255


section    .text

    extern  malloc
    extern  free

    global  juliaGenerateImage

        struc   Image
w:          resq    1
h:          resq    1
realw:      resq    1
pixels:     resq    1
    	endstruc

juliaGenerateImage: 
            call    newImage
            mov     r10, [rax + pixels]
            mov     rdi, [rax + w]
            mov     rsi, [rax + h]
            mov     r8, [rax + realw]
            mov     r9, [rax + h]       ;; number of .loop_h iterations (number of rows)
            shr     rdi, 1              ;; ReZ
            shr     rsi, 1              ;; ImZ
            shr     r8, 2               ;; number of .loop_w iterations
            neg     rdi                 ;; Let ReZ will be from - to + (from upper left corner of the screen)
            neg     rsi

            
            xorps  xmm8, xmm8
            movss  xmm8, [A]             
            shufps xmm8, xmm8, 0       ;; YMM8 = A

            xorps  xmm9, xmm9
            movss  xmm9, [B]
            shufps xmm9, xmm9, 0       ;; YMM9 = B
            
                                        ;; R = (1 + sqrt(1 + 4|c|))/2
            movaps   xmm5, xmm8
            mulps   xmm5, xmm8
            movaps   xmm2, xmm9
            mulps   xmm2, xmm9
            addps  xmm5, xmm2
            movups  xmm2, [ONE]
            addps  xmm5, xmm2
            sqrtps xmm5, xmm5
            addps  xmm5, xmm2
            movups xmm2, [TWO]
            divps  xmm5, xmm2   ;; YMM5 = R

            movss  xmm10, [SCALE] 
            shufps xmm10, xmm10, 0      ;; YMM10 = SCALE

            movups  xmm11, [REZ_START]
            mulps  xmm11, xmm10         ;; YMM11 = REZ_START 

            movups  xmm12, [REZ_SHIFT]
            mulps  xmm12, xmm10         ;; YMM12 = REZ_SHIFT

            movups  xmm14,  [TWO]               ;; YMM14 = TWO

            mov     rdx, [MAXN]
            mov     [BUFFER32], edx
            xorps  xmm15, xmm15
            movss  xmm15, [BUFFER32]
            shufps xmm15, xmm15, 0      ;; YMM15 = MAXN

            cvtsi2ss xmm1, rsi
            shufps xmm1, xmm1, 0
            mulps  xmm1, xmm10           ;; YMM1 = ImZ (b)  

.loop_h:    cvtsi2ss  xmm0, rdi             ;; start from the beginning of the new line
            shufps xmm0, xmm0, 0         ;; YMM0 = ReZ (b)
            mulps  xmm0, xmm10
            addps  xmm0, xmm11
            mov     r8, [rax + realw]
            shr     r8, 2


.loop_w:    xor     rcx, rcx
            mov     ecx, [MAXN]                 ;; counter of the 0..MAXN iterations
            movss  xmm6, [MAXN]             ;; YMM6 = N
            shufps  xmm6, xmm6, 0
            
            movaps  xmm7, xmm0
            movaps  xmm13, xmm1

            .loop_n:    movaps   xmm2, xmm0
            mulps  xmm2, xmm0            ;; YMM2 = a*a - b*b + A (see c++ code)
            movaps   xmm3, xmm1
            mulps  xmm3, xmm1
            subps  xmm2, xmm3          
            addps  xmm2, xmm8      
        
            movaps   xmm3, xmm0
            mulps  xmm3, xmm1            ;; YMM3 = 2*a*b + B (see c++ code)
            mulps  xmm3, xmm14
            addps  xmm3, xmm9
            
            movaps xmm0, xmm2                  ;; a = YMM2
            movaps xmm1, xmm3                  ;; b = YMM3
            
            mulps xmm2, xmm2          
            mulps xmm3, xmm3
            addps   xmm2, xmm3
            sqrtps xmm2, xmm2
            cmpltps xmm2, xmm5           ;; if Rn < R then +1 to N else +0 to N
            paddd  xmm6, xmm2
            dec     rcx
            jnz     .loop_n

            movaps xmm0, xmm7
            movaps  xmm1, xmm13

            movups [r10], xmm6                 ;; store colors to memory
            lea     r10, [r10 + 16]
            
            addps   xmm0, xmm12           ;; shift real part to the right by 8 cells
            dec     r8
            jnz     .loop_w

            addps   xmm1, xmm10         ;; shift imagine part to a row below
            dec     r9
            jnz     .loop_h
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





newImage:   syspush
            push    rdi
            push    rsi
            mov     rdi, Image_size
            call    alligned_malloc
            pop     rsi
            pop     rdi
            mov     [rax + w], rdi
            mov     [rax + h], rsi
            push    rax
            mov     rax, rdi
            ceil    rax
            mov     rcx, rax
            mul     rsi
            mov     rdi, rax
            shl     rdi, 2
            push    rcx
            call    alligned_malloc
            pop     rcx
            pop     rdx
            mov     [rdx + realw], rcx
            mov     [rdx + pixels], rax
            mov     rax, rdx
            syspop
            ret
