; Sua tarefa será escrever dois programas utilizando a linguagem montagem para processadores intel x86/64, utilizando o montador NASM.
; O primeiro programa deverá converter um número decimal para float;
; O segundo programa deverá converter um número float para decimal;
; Em ambos os casos o resultado deverá ser impresso na tela;
; Em ambos os casos a entrada deverá ser via teclado;

; [Restrições]
; Para isso considere: A representação float segue a norma IEEE 754, exceto por apresentar a seguinte distribuição de bits:
; Um bit para sinal;
; Sete bits para o campo expoente;
; Oito bits para o campo fracionário;

; Você deverá considerar o arredondamento quando for o caso;
; É apenas permitido a utilização de registradores de uso geral (r0 à r15), exceto aqueles de uso restrito;
; Não é permitido o uso da pilha para armazenamento temporário;

; [Submissão]
; O seu código deverá ser publicado no github;
; Você deverá submeter o seu código com o link do github para esta atividade
; O seu código deverá conter na seção inicial, comentários explicando o funcionamento geral do programa;
;
; To assemble and run:
;
;     nasm -felf64 swb.asm && ld swb.o && ./a.out
; --------------------------------------------------------------------------------------------------------------------------------------------
; section .data
;   db  = define byte        (8 bits)
;   dw  = define word        (2 * 8 bits = 16 bits)
;   dd  = define double word (2 * 16 bits = 32 bits)
;   dq  = define quad word   (4 * 16 bits = 64 bits)
;   0   = termination (\0)
;   10  = termination (\n)
;   13  = carriage return
;
; section .bss
;   resb = reserve byte
;   resw = reserve word
;   resd = reserve double word
;   .
;   .
;   .

STDIN equ 0
STDOUT equ 1
STDERR equ 2

SYS_READ equ 0
SYS_WRITE equ 1
SYS_EXIT equ 60

%macro exit 0
    mov rax, SYS_EXIT   ; system call for exit
    xor rdi, rdi        ; exit code 0
    syscall             ; invoke operating system to exit
%endmacro

%macro print 2

    mov rax, SYS_WRITE  ; systemcall for write
    mov rdi, STDOUT     ; file handle 1 is stdout
    mov rsi, %1         ; address of string to output
    mov rdx, %2         ; number of bytes
    syscall

%endmacro

%macro printInt 1

    mov rax, %1
	add rax, '0'
	mov [digit], al
	mov rax, SYS_WRITE
	mov rdi, STDOUT
	mov rsi, digit
	mov rdx, 2
    syscall

%endmacro

%macro scan 2

    mov rax, SYS_READ   ; systemcall for read
    mov rdi, STDIN     ; file handle 1 is stdout
    mov rsi, %1         ; address of string to output
    mov rdx, %2         ; number of bytes
    syscall

%endmacro

section .data
    resdiv db "RESULTADO DIV: "
    resres db "RESTO: "
    askNum db "Entre com o decimal",10
    len equ $-askNum
    askNum1 db "TESTE",10
    len1 equ $-askNum1
    digit db 0,10
    buffer times 16 db 0

section .bss
    ascii resb 1

section .text
    global _start

    _start:
        print askNum, len
        scan ascii, 16
        call _strToInt
        call _lascaDiv
        print buffer, 16
        exit

    _strToInt:                  ; int salvo em rax
        movzx rax, byte[rsi]	; Pega primeiro byte da string
		sub rax, '0'			; Transforma para "Inteiro"
		cmp al, 9				; Checa se é um digito (Entre 0-9)
		jbe .loopEntry			; Se for digito pula para o Loop_Entry
		xor rax, rax			; Se não for retorna 0
		ret
		.nextNum:			    ; Salva o digito em rax
		lea rax, [rax*4 + rax]	; Total *= 5
		lea rax, [rax*2 + rcx]	; Total = Total*2 + Digito
		.loopEntry:
		inc	rsi					; Pula para o segundo byte
		movzx rcx, byte[rsi]	; Move o byte para ECX
		sub rcx, '0'			; Transforma para "Inteiro"
		cmp rcx, 9				; Checa se é um digito (Entre 0-9)
		jbe .nextNum			; Se for digito pula para o Next_Digit
        mov r15, rax
		ret						; Se não acabou os números válidos e retorna

    _modTwo:
        mov rdx, 0              ; Resto
        mov rcx, 2              ; Divide por 2
        div rcx                 ; rax / rcx = rax
        mov r13, rax            ; R13 guarda RESULTADO DA DIV
        mov r14, rdx            ; R14 guarda RESTOS
        ret

    _concat:
        mov rax, r14
        add rax, '0'
        mov [buffer + r12], rax
        ret

    _lascaDiv:
        mov rax, r15
        mov r12, 0
        mov r11, 0
        .recur:
            call _modTwo
            inc r12
            print resdiv, 15
            printInt r13
            print resres, 7
            printInt r14
            call _concat
            mov rax, r13
            cmp r13, 0
            jnz .recur
        mov [buffer + 15], r11
        ret