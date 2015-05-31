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


REZ_START:  dd  0,1,2,3,4,5,6,7
REZ_SHIFT:  dd  8,8,8,8,8,8,8,8
ONE:        dd  1,1,1,1,1,1,1,1
TWO:        dd  2,2,2,2,2,2,2,2    

WHITE:      dd  0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff

; TODO : malloc
BUFFER:     resd    1

        ;;  c = A + i*B  
A:          dd      0.28
B:          dd      0.0113
SCALE:      dd      0.001
MAXN:       dd      500

%macro colorize 1
        vsubps  %1, ymm15, %1
        vdivps  %1, %1, ymm15
        vmulps  %1, %1, [WHITE]
%endmacro

juliaGenerateImage: 
            call    newImage
            mov     r10, [rax + pixels]
            mov     rdi, [rax + w]
            mov     rsi, [rax + h]
            mov     r8, [rax + realw]
            mov     r9, [rax + h]       ;; number of .loop_h iterations (number of rows)
            shr     rdi, 1              ;; ReZ
            shr     rsi, 1              ;; ImZ
            shr     r8, 3               ;; number of .loop_w iterations
            neg     rdi                 ;; Let ReZ will be from - to + (from upper left corner of the screen)
            neg     rsi

            
            vxorps  ymm8, ymm8, ymm8
            vmovss  xmm8, [A]             
            vshufps ymm8, ymm8, ymm8, 0       ;; YMM8 = A

            vxorps  ymm9, ymm9, ymm9
            vmovss  xmm9, [B]
            vshufps ymm9, ymm9, ymm9, 0       ;; YMM9 = B
            
                                        ;; R = (1 + sqrt(1 + 4|c|))/2
            
            vmulps  ymm5, ymm8, ymm8
            vmulps  ymm2, ymm9, ymm9
            vaddps  ymm5, ymm5, ymm2
            vaddps  ymm5, ymm5, [ONE]
            vsqrtps ymm5, ymm5
            vaddps  ymm5, ymm5, [ONE]
            vdivps  ymm5, ymm5, [TWO]   ;; YMM5 = R

            vxorps  ymm10, ymm10, ymm10
            vmovss  xmm10, [SCALE] 
            vshufps ymm10, ymm10, ymm10, 0      ;; YMM10 = SCALE

            vmovups  ymm11, [REZ_START]
            vmulps  ymm11, ymm11, ymm10         ;; YMM11 = REZ_START 

            vmovups  ymm12, [REZ_SHIFT]
            vmulps  ymm12, ymm12, ymm10         ;; YMM12 = REZ_SHIFT

            vmovups  ymm13, [ONE]                ;; YMM13 = ONE
            vmulps  ymm13, ymm13, ymm10         

            vmovups  ymm14,  [TWO]               ;; YMM14 = TWO

            mov     rdx, [MAXN]
            mov     [BUFFER], edx
            vxorps  ymm15, ymm15, ymm15
            vmovss  xmm15, [BUFFER]
            vshufps xmm15, xmm15, xmm15, 0      ;; YMM15 = MAXN

            mov     [BUFFER], esi
            vxorps  ymm1, ymm1, ymm1
            vmovss  xmm1, [BUFFER]   
            vshufps ymm1, ymm1, ymm1, 0
            vmulps  ymm1, ymm1, ymm10           ;; YMM1 = ImZ (b)  

.loop_h:    mov     [BUFFER], edi
            vxorps  ymm0, ymm0, ymm0
            vmovss  xmm0, [BUFFER]              ;; start from the beginning of the new line
            vshufps ymm0, ymm0, ymm0, 0         ;; YMM0 = ReZ (b)
            vmulps  ymm0, ymm0, ymm10
            vaddps  ymm0, ymm0, ymm11
            

.loop_w:    mov     rcx, [MAXN]                 ;; counter of the 0..MAXN iterations
            vxorps  ymm6, ymm6, ymm6            ;; YMM6 = N
.loop_n:    vmulps  ymm2, ymm0, ymm0            ;; YMM2 = a*a - b*b + A (see c++ code)
            vmulps  ymm3, ymm1, ymm1
            vsubps  ymm2, ymm2, ymm3          
            vaddps  ymm2, ymm2, ymm8      
            vmulps  ymm3, ymm0, ymm1            ;; YMM3 = 2*a*b + B (see c++ code)
            vmulps  ymm3, ymm3, ymm14
            vaddps  ymm3, ymm3, ymm9
            vmovaps ymm0, ymm2                  ;; a = YMM2
            vmovaps ymm1, ymm3                  ;; b = YMM3
            vmulps ymm2, ymm2, ymm2          
            vmulps ymm3, ymm3, ymm3
            vaddps  ymm2, ymm2, ymm3
            vsqrtps ymm2, ymm2
            vcmpltps ymm2, ymm2, ymm5           ;; if Rn < R then +1 to N else +0 to N
            vminps  ymm2, ymm2, ymm13
            vaddps  ymm6, ymm6, ymm2
            dec     rcx
            jnz     .loop_n
            
            colorize ymm6
            vmovups [r10], ymm6                 ;; store colors to memory
            lea     r10, [r10 + 256]
            vaddps  ymm0, ymm0, ymm12           ;; shift real part to the right by 8 cells
            dec     r8
            jnz     .loop_w

            vsubps  ymm1, ymm1, ymm10         ;; shift imagine part to a row below
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
            pop     rdi
            pop     rsi
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
            ret
