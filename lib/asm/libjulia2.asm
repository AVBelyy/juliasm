            %define PIC_SIZE_X 1200
            %define PIC_SIZE_Y 800
            
            %define ITERATIONS 64
            
            %define PIC_SIZE_X_FLOAT_HALF 400.0
            %define PIC_SIZE_Y_FLOAT_HALF 400.0
            
            SECTION .rodata
            out_fn: db "mandel.bmp", 0
            out_mode: db "wb", 0
            hdr: db "BM"
            dd 0 ; 14 + 40 + width*height*3
            dd 0, 54, 40
            dd 0, 0 ; width, -height
            db 1, 0, 24, 0
            dd 0, 0, 0, 0, 0, 0
            hdr_len equ $ - hdr
            
            align 16
            divisors: dq PIC_SIZE_X_FLOAT_HALF
            dq PIC_SIZE_Y_FLOAT_HALF
            halves: dq 2.0, 1.0
            negators: dq -1.0, 1.0
            radius: dq 4.0, 4.0
            
            SECTION .text
            extern fopen
            extern fwrite
            extern fputc
            extern memcpy
            
            global main
            
            main:
            enter 0, 0
            push r12
            
            ; r12 = fopen("mandel.bmp", "wb")
            mov rdi, out_fn
            mov rsi, out_mode
            call fopen
            mov r12, rax
            
            ; local header
            sub rsp, hdr_len
            
            ; memcpy(header, hdr, hdr_len)
            mov rdi, rsp
            mov rsi, hdr
            mov rdx, hdr_len
            call memcpy
            
            ; rax = PIC_SIZE_X*PIC_SIZE_Y*3
            mov rax, PIC_SIZE_X
            mov rcx, PIC_SIZE_Y
            mul rcx
            mov rcx, 3
            mul rcx
            ; header[2] = eax
            mov dword [rsp + 2], eax
            ; header[18] = PIC_SIZE_X
            mov dword [rsp + 18], PIC_SIZE_X
            ; header[22] = -PIC_SIZE_Y
            mov rax, PIC_SIZE_Y
            neg rax
            mov dword [rsp + 22], eax
            
            ; fwrite(header, hdr_len, 1, r12);
            mov rdi, rsp
            mov rsi, hdr_len
            mov rdx, 1
            mov rcx, r12
            call fwrite
            
            ; remove local heder
            add rsp, hdr_len
            
            ; for rcx = pic_size_y to 0
            mov rcx, PIC_SIZE_Y
            
            .loop_y:
            push rcx
            
            ; rdx = rcx; for rcx = pic_size_x to 0
            mov rdx, PIC_SIZE_X
            xchg rdx, rcx
            
            .loop_x:
            push rcx
            
            ; xmm0 = (rbx, rcx)
            cvtsi2sd xmm1, rdx
            cvtsi2sd xmm0, rcx
            
            call .complex_calc_pre
            
            mov rcx, ITERATIONS
            .loop_iter:
            
            call .complex_calc ; xmm stuff happense here
            
            jnc .out_of_iter
            
            loop .loop_iter
            .out_of_iter:
            
            push rdx
            
            mov rax, rcx
            mov rbx, 15
            mul rbx
            mov rbx, rax
            shl rbx, 8
            or rax, rbx
            shl rbx, 8
            or rax, rbx
            
            
            ; move rax to memory
            push rax
            
            ; fwrite(rax, 3, 1, r12)
            mov rdi, rsp
            mov rsi, 3
            mov rdx, 1
            mov rcx, r12
            call fwrite
            
            add rsp, 8 ; rax
            
            pop rdx
            
            pop rcx ; rcx
            loop .loop_x
            
            pop rcx
            loop .loop_y
            
            pop r12
            
            ; return 0
            xor rax, rax
            leave
            ret
            
            .complex_calc_pre:
            enter 0, 0
            
            unpcklpd xmm0, xmm1 ; movlhps xmm0, xmm1
            
            ; xmm0 /= divisors
            movaps xmm2, [divisors]
            divpd xmm0, xmm2
            
            ; xmm0 -= halves
            movaps xmm2, [halves]
            subpd xmm0, xmm2
            
            ; xmm1 = xmm0
            movaps xmm1, xmm0
            
            leave
            ret
            
            
            
            .complex_calc:
            enter 0, 0
            
            movaps xmm3, xmm0
            
            ; xmm3 = straight product aa', bb'
            mulpd xmm3, xmm0
            
            ; xmm2 = cross product ab', a'b
            pshufd xmm2, xmm0, 0x4e ; bits: 01001110
            mulpd xmm2, xmm0
            
            ; xmm4 = aa', ab'
            movaps xmm4, xmm3
            unpcklpd xmm4, xmm2
            ; movhps xmm4, xmm2
            ; movlps xmm4, xmm3
            
            ; xmm5 = ab', bb'
            movaps xmm5, xmm3
            unpckhpd xmm5, xmm2
            
            ; xmm5 = -bb', ab'
            movapd xmm2, [negators]
            mulpd xmm5, xmm2
            
            ; xmm0 = aa'-bb', a'b+ab'
            movaps xmm0, xmm4
            addpd xmm0, xmm5
            
            ; xmm0 += xmm1
            addpd xmm0, xmm1
            
            ; xmm2 = (xmm0)^2
            movaps xmm2, xmm0
            mulpd xmm2, xmm2
            
            ; xmm2 = xmm2lo + xmm2hi
            pshufd xmm3, xmm2, 0x4e
            addpd xmm2, xmm3
            
            ; cmp xmm2lo, 2.0
            movaps xmm3, [radius]
            comisd xmm2, xmm3
            
            leave
            ret

