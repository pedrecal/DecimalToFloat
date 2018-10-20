STDIN equ 0
STDOUT equ 1
STDERR equ 2

SYS_READ equ 0
SYS_WRITE equ 1
SYS_EXIT equ 60

FLOAT_BIAS equ 63

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


;Input
;   r14 = resto da divisão
;Output
;   buffer com os restos concatenados

%macro concat 2

    mov rax, %1
    add rax, '0'
    mov [%2 + r12], rax

%endmacro

section .data
    askNum db "Entre com o decimal",10
    len equ $-askNum
    digit db 0,10
    buffer times 8 db 0
    reffub times 8 db 0

section .bss
    ascii resb 1

section .text
    global _start

    _start:
        print askNum, len
        scan ascii, 16
        call _strToInt
        call _makeFrac
        print reffub, 8

        exit

    ;Input
    ;   rsi = string com o num
    ;Output
    ;   rax = string convertida pra int

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
		ret						; Se não acabou os números válidos e retorna

    ;Input
    ;   rax = num a ser dividido
    ;Output
    ;   r14 = resto a cada iteração
    ;   r13 = result da div a cada iteração
    _modTwo:
        mov rdx, 0              ; Resto
        mov rcx, 2              ; Divide por 2
        div rcx                 ; rax / rcx = rax
        mov r13, rax            ; R13 guarda RESULTADO DA DIV
        mov r14, rdx            ; R14 guarda RESTOS
        ret

    ;Input
    ;   r15 = inteiro original, dada entrada
    ;Output
    ;   r14 = resto a cada iteração
    ;   r13 = result da div a cada iteração
    ;   r12 = qtd de bits, usado em concat
    _lascaDiv:
        mov rax, r15
        mov r12, 0
        .recur:
            call _modTwo
            inc r12
            concat r14, buffer
            mov rax, r13
            cmp r13, 0
            jnz .recur
        ret

    ;Input
    ;   buffer = restos já cocatenados, porém ao contrário
    ;Output
    ;   reffub = buffer ao contrário

    _reverseStr:
        mov r10, 8
        mov r11, 0
        .recur:
            mov r9, [buffer + r10]
            mov [reffub + r11], r9
            dec r10
            inc r11
            cmp r10, 0
            jnz .recur
        ret

    _makeFrac:
        mov r15, rax
        call _lascaDiv
        call _reverseStr
        ret
