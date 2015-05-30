section    .text
    
    extern  malloc
    extern  free

    global  juliaGenerateImage

    struc   Image_t
w:          resq    1
h:          resq    1
realw:      resq    1
pixels:     resq    1
    endstruc


REZ_START:  dd  0,1,2,3,4,5,6,7
REZ_SHIFT:  dd  8,8,8,8,8,8,8,8
ONE:        dd  1,1,1,1,1,1,1,1
TWO         dd  2,2,2,2,2,2,2,2    

BUFFER:     resd    1
MAXN:       resq    100

        ;;  c = A + i*B  
A:          dd      1.28
B:          dd      0.0113


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
            
            mov     [BUFFER], esi
            vmovss  xmm1, [BUFFER]           ;; YMM1 - ImZ (b)
            vshufps ymm1, ymm1, ymm1, 0
            vmovss  xmm8, [A]             
            vshufps ymm8, ymm8, ymm8, 0       ;; YMM8 = A
            vmovss  xmm9, [B]
            vshufps ymm9, ymm9, ymm9, 0       ;; YMM9 = B
            
            push    rax                 ;; Radius calculation:
            mov     rax, [A]            ;; R = (1 + sqrt(1 + 4|c|))/2
            mul     rax
            mov     rcx, rax
            mov     rax, [B]
            mul     rax
            add     rax, rcx
            mov     rcx, 4
            mul     rcx
            add     rax, 1
            mov     [BUFFER], rax
            fld     qword [BUFFER]
            fsqrt   
            fst     qword [BUFFER]
            mov     rax, [BUFFER]
            add     rax, 1
            shr     rax, 1
            mov     [BUFFER], eax
            vmovss   xmm5, [BUFFER]
            vshufps ymm5, ymm5,  ymm5, 0       ;; YMM5 = R
            pop     rax
           
.loop_h:    mov     [BUFFER], edi
            vmovss  xmm0, [BUFFER]           ;; start from the beginning of the new line
            vshufps ymm0, ymm0, ymm0, 0       ;; YMM0 = ReZ (b)
            vaddps  ymm0, ymm0, [REZ_START]
.loop_w:    mov     rcx, [MAXN]           ;; counter of the 0..MAXN iterations
            vxorps  ymm6, ymm6, ymm6          ;; YMM6 - N (colors)
.loop_n:    vmulps  ymm2, ymm0, ymm0    ;; YMM2 = a*a - b*b + A (see c++ code)
            vmulps  ymm3, ymm1, ymm1    ;;
            vsubps  ymm2, ymm2, ymm3          
            vaddps  ymm2, ymm2, ymm8      
            vmulps  ymm3, ymm0, ymm1    ;; YMM3 = 2*a*b + B (see c++ code)
            vmulps  ymm3, ymm3, [TWO]
            vaddps  ymm3, ymm3, ymm9
            vmovaps ymm0, ymm2          ;; a = YMM2
            vmovaps ymm1, ymm3          ;; b = YMM3
            vmulps ymm2, ymm2, ymm2          
            vmulps ymm3, ymm3, ymm3
            vaddps  ymm2, ymm2, ymm3
            vsqrtps ymm2, ymm2
            vcmpltps ymm2, ymm2, ymm5   ;; if Rn < R then +1 to N else +0 to N
            vminps  ymm2, ymm2, [ONE]
            vaddps  ymm6, ymm6, ymm2
            dec     rcx
            jnz     .loop_n
            vmovups [r10], ymm6           ;; store colors to memory
            lea     r10, [r10 + 256]
            vaddps  ymm0, ymm0, [REZ_SHIFT]     ;; shift real part to the right by 8 cells
            dec     r8
            jnz     .loop_w
            vsubps  ymm1, ymm1, [ONE]           ;; shift imagine part to a row below
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
            mov     rdi, Image_t_size
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
