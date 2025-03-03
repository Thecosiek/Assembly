; Implementation of function mdiv which is capable of dividing very big number. Int64_t mdiv(int64_t *x, size_t n, int64_t y);
; The function performs integer division with remainder. The function treats the dividend, divisor, quotient, and remainder as 
; numbers encoded in two's complement. The first and second parameters of the function specify the dividend: x is a pointer to a non-empty 
; array of n 64-bit numbers. The dividend has 64 * n bits and is stored in memory in little-endian order. The third parameter y is the divisor.
; The result of the function is the remainder of the division of x by y. The function places the quotient in the array x.
; If the quotient cannot be stored in the array x, it indicates an overflow. A special case of overflow is division by zero. 
; The function should handle overflow as the div and idiv instructions do, meaning it should trigger interrupt number 0. 
; In Linux, this is handled by sending the process a SIGFPE signal. 

section .text
global mdiv
mdiv:
    mov r9, rdx                 ; Pomocniczo r9 = dzielnik

.overflow_test:                 ; Testowanie overflowa
    mov rax, [rdi + 8*rsi - 8]  ; Ustawiamy najbardziej znaczaca pozycje w rax

    mov rcx, 0                  
    dec rcx
    cmp r9, rcx                 ; Sprawdzamy czy dzielnik to -1
    jne .znak_dzielnej

    mov rdx, 0x80000000         ; Sprawdzamy czy wartosc z rax to
    shl rdx, 32                 ; 0x8000000000000000 czyli llmin
    cmp rax, rdx
    jne .znak_dzielnej

    mov rcx, rsi                
    dec rcx

    cmp rcx, 0                  ; Jesli tablica ma wielkosc 1
    jne .czy_zero_loop  
    mov rcx, 0                  ; Zglaszamy overflowa
    div rcx
    ret

.czy_zero_loop:                 ; Jesli jest wieksza niz 1
    mov rax, [rdi + 8*rcx - 8]
    cmp rax, 0                  ; Sprawdzamy czy pozostale bity sa zerami
    jne .znak_dzielnej          
    dec rcx
    jnz .czy_zero_loop

    mov rcx, 0                  ; Jesli na poczatku jest 0x8000000000000000
    div rcx                     ; A pozniej same zera, to zglaszamy overflowa
    ret

.znak_dzielnej:
    xor rax, rax
    xor rdx, rdx

    mov rax, [rdi + 8*rsi - 8] 	; Zaladuj poczatek dzielnej
    test rax, rax				; Sprawdz pierwszy bit (czyli znak)
    jns .dodatnia_dzielna       ; Jesli zero, pomin zamiane na dodatnia

    xor rax, rax                ; Wyzerowanie rejestru rax

    mov rcx, rsi				
.negacja_dzielnej:              ; Zamiana bitow w dzielnej
    not qword [rdi + 8*rcx - 8]
    dec rcx
    jnz .negacja_dzielnej

    add qword [rdi], 1          ; Dodanie 1 do dzielnej

.przeniesienie_dzielna:         ; Przenoszenie bitow
    inc rcx
    adc qword [rdi + 8*rcx], 0
    jc .przeniesienie_dzielna

    mov r10B, 1					; Oznacz ujemna dzielna
    jmp .znak_dzielnika

.dodatnia_dzielna:

    mov r10B, 0                  ; Oznacz dodatnia dzielna

.znak_dzielnika:

    test r9, r9				    ; Sprawdzenie znaku dzielnika	
    jns .dodatni_dzielnik

    neg r9 					    ; Dzielnik jest ujemny - zamiana na dodatni
    mov r11B, 1					; Oznacz, ze dzielnik byl ujemny
	jmp .dzielenie

.dodatni_dzielnik:
	mov r11B, 0					; Oznacz ze dzielnik byl dodatni

.dzielenie:
    xor rdx, rdx				; Przygotowanie reszty RDX = 0
    
    mov rcx, rsi	
.petla_dzielenia:               ; Dzielenie w petli
    mov rax, [rdi + 8*rcx - 8]	
    div r9
    mov [rdi + 8*rcx - 8], rax	
	dec rcx
    jnz .petla_dzielenia

    cmp r10B, r11B			    ; Porownanie znaku dzielnika i dzielnej
    je .znak_reszty				; Jesli sa identyczne, to pomin zamiane wyniku na ujemny

    mov rcx, rsi				
.negacja_wyniku:                ; Zamiana bitow w wyniku z tablicy x
    not qword [rdi + 8*rcx - 8]
    dec rcx
    jnz .negacja_wyniku

    add qword [rdi], 1          ; Dodanie 1 do wyniku

.przeniesienie_wynik:           ; Przenoszenie bitow
    inc rcx
    adc qword [rdi + 8*rcx], 0
    jc .przeniesienie_wynik

.znak_reszty:                   ; Zmiana znaku reszty w zaleznosci od dzielnej
    cmp r10B, 1                   ; Sprawdzenie znaku dzielnej
    jne .done
    neg rdx                     ; Negacja reszty

.done:                          ; Zwrocenie Wyniku
    mov rax, rdx
    ret
