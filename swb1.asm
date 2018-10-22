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
;     nasm -felf64 swb1.asm && ld swb1.o && ./a.out
;

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

;Input
;   buffer = restos já cocatenados, porém ao contrário
;Output
;   reffub = buffer ao contrário


%macro reverseStr 3

    mov r12, %1
    mov r11, 0
    .recur:
        mov r10, [%2 + r12]
        mov [%3 + r11], r10
        dec r12
        inc r11
        cmp r12, 0
        jnz .recur

%endmacro

%macro copyStr 2

    mov rax, [%1]
    mov [%2], rax

%endmacro

section .data
    resdiv db "RESULTADO DIV: "
    resres db "RESTO: "
    askNum db "Entre com o decimal",10
    len equ $-askNum
    digit db 0,10
    buffer times 16 db 0
    reffub times 16 db 0
    exp times 16 db 0
    frac times 16 db 0
    sign db 0
    signB db 0

section .bss
    ascii resb 1

section .text
    global _start

    _start:
        print askNum, len
        scan sign, 1
        call _signCompare
        scan ascii, 16

        call _strToInt
        mov r15, rax

        call _makeFrac
        ; call _copyString
        ; print reffub, 16    ;Printa FRAC

        call _makeExp
        print signB, 1
        print reffub, 16  ;Printa EXP
        print frac, 16

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

    _reverseStr:
        mov r10, 16
        mov r11, 0
        .recur:
            mov r9, [buffer + r10]
            mov [reffub + r11], r9
            dec r10
            inc r11
            cmp r10, 0
            jnz .recur
        ret

    _reverseStrFrac:
        mov r10, r12
        mov r11, 0
        .recur:
            mov r9, [buffer + r10 - 1]
            mov [reffub + r11], r9
            dec r10
            inc r11
            cmp r10, 0
            jnz .recur
        ret

    _completeWZeros:
        mov r15, 48
        mov r8, r12
        .recur:
            mov [reffub + r8], r15
            inc r8
            cmp r8, 8
            jne .recur
        ret

    _copyString:
        mov rax, [reffub]
        mov [frac], rax
        ret

    _makeExp:
        lea rax, [FLOAT_BIAS + r12]
        dec rax
        mov r15, rax
        call _lascaDiv
        call _reverseStr
        mov r15, 0
        mov [reffub + 0], r15
        ret

    _makeFrac:
        call _lascaDiv
        call _reverseStrFrac
        call _completeWZeros
        copyStr reffub, frac
        ret

    _signCompare:
        mov r15, [sign]         ; Joga bit de sinal em r15
        mov r14, 43             ; Joga sinal + em r14
        cmp r15, r14            ; Compara sinal entrado com +
        jne .setNeg             ; Se for diferente pula pra .setNeg
        mov r14, 48             ; joga 0 em r14
        mov [signB], r14        ;
        jmp .done
        .setNeg:
            mov r14, 49         ; Joga 1 em r14
            mov [signB], r14    ; joga 1 em signB
        .done:
            ret
        ret