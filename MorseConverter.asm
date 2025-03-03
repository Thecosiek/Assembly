; This code convertes message written in latin alphabet into morse code reprezented as dots and dashes and vice versa depending on input.
; All spaces written in input are preserved in output. Using wrong char or unexisting morse code results in code 1 (error)


global _start
    ; Stałe do obsługi funkcji systemowych
    STDIN equ 0
    STDOUT equ 1

    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_EXIT equ 60

    SUCCES_CODE equ 0
    ERROR_CODE equ 1

    BUFFER_SIZE equ 1024
    DIGIT_SIZE equ 5
    MAX_CODE_SIZE equ 6

section .data 
    ; Kody Morse'a dla liter od A do Z
    morse_letters db ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.."

    ; Kody Morse'a dla cyfr od 0 do 9
    morse_digits db "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----."

    ; Długości kodów dla liter (w przypadku cyfr ta długość to zawsze 5)
    morse_lenghts db 2, 4, 4, 3, 1, 4, 3, 4, 2, 4, 3, 4, 2, 2, 3, 4, 4, 3, 3, 1, 3, 4, 3, 4, 4, 4

    ; Tablica z literami alfabetu
    alphabet db 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0'

    ; Tablica z cyframi 0 - 9
    digits db '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
        
    space_output db ' '

section .bss
    ; Deklaracja miejsca na input i output
    input_buffer resb 1024
    output_buffer resb 1024
    single_morse resb 6

section .text

_start:

    ; Odczytywanie wejscia z stdin, wywołanie sys_read
    mov rax, SYS_READ 
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, BUFFER_SIZE
    syscall 

    ; Trzymamy dane z  wejścia w RSI
    mov rsi, input_buffer
    mov rdi, output_buffer

    ; Test poprawności zczytania danych
    test rax, rax
    js error_exit

    mov r8, rax
    
    ; Zdeterminowanie kierunku konwersji
    call convertion_direct

    ; Pierwszy znak inny niż spacja znajduje się w al
    ; RSI - pointer na pierwszy znak inny niż spacja

    ; Jesli ten znak to '.' lub '-', to konwersja jest z morse'a na alfabet
    cmp al, '.'        
    je decode_morse
    cmp al, '-'         
    je decode_morse

    ; Jesli znak jest mniejszy niż '0' (z punktu widzenia ASCII) to niepoprawne wejscie (bo wiemy że znak jest inny niż '.' lub '-')
    cmp al, '0'
    jb error_exit
    cmp al, '9'
    ; Jesli pomiedzy 0 a 9 to następuje konwersja na morse'a
    jbe text_to_morse   

    ; Jesli znak jest mniejszy niż 'A' albo większy niż 'Z' to wejście jest niepoprawne (wiadomo że to nie jest '.', '-' albo cyfra)
    cmp al, 'A'
    jb error_exit
    cmp al, 'Z'
    ja error_exit
    ; Przeciwnie, jest to na pewno znak z zakresu A do Z, więc zamieniamy na morse'a
    jmp text_to_morse
   
convertion_direct:  ; Wyszukiwanie pierwszego znaku nie będącego spacją
    mov al, [rsi]
    cmp al, ' '
    je skip_space
    cmp al, 0
    je done
    ret
skip_space:         ; Dopóki al jest spacją, sprawdzaj kolejny znak ładując go do al
    mov byte[rdi], ' '
    inc rdi
    inc rsi
    jmp convertion_direct
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; ZAMIANA Z ALFABETU NA KOD MORSE'A
; rsi - wskaźnik na pierwszy znak inny niż spacja, rdi - wskaźnik na pierwsze miejsce w outpucie, al - pierwszy znak, rbx - wskaznik na cyfry lub litery
; rcx - licznik dlugosci dla danego znaku w jego interpretacji na morse'a, r9 - wskaznik na dlugosci kodow (uzywany tylko dla liter, gdyz dla cyfr jest to zawsze 5)

read:   ;ponowne zczytanie z inputu
    mov r12, rdi    ; Zapamiętujemy rdi

    mov rax, SYS_READ 
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, BUFFER_SIZE
    syscall 

    mov rdi, r12    ; Przywracamy rdi 

    test rax, rax   ; Sprawdzamy poprawnosc funkcji systemowej
    js error_exit
    je done         ; Jesli doszlismy do konca inputu, to konczymy

    mov r8, rax     ; Zapamietujemy ilosc wczytanych znakow

text_to_morse:

convert_text_loop:

    mov al, byte[rsi] ; Bierzemy kolejny znak inputu

    cmp al, 0       ; Jeśli null, to koniec inputu
    je done 

    cmp al, ' '
    je add_space ; Jesli spacja, to poprostu ja kopiujemy

    cmp al, '0'   ; Jesli liczba od 0 do 9 to ja zamieniamy
    jb error_exit
    cmp al, '9'
    jbe digit_to_morse

    cmp al, 'A'   ; Analogicznie dla liter od A do Z
    jb error_exit
    cmp al, 'Z'
    ja error_exit   ; Jeśli znak nie jest Null'em, spacją, literą lub cyfrą, to jest niepoprawny - wychodzimy z kodem błędu

    jmp letter_to_morse


add_space:
    mov byte [rdi], ' ' ; Przenosimy spacje do outputu
    inc rdi             ; Przechodzimy na kolejne miejsce outputu i sprawdzamy, czy output nie wymaga przedluzenia

    mov rax, rdi        ; Sprawdzamy ilosc zapisanych znakow
    sub rax, output_buffer  ; Jesli jest rowna

    cmp rax, 1018       ; BUFFER_SIZE - 6, bo tyle zajmuje najdluzej znak + spacja
    ja write            ; To przedluzamy out put
next:
    inc rsi             ; Przechodzimy na kolejne miejsce inputu i sprawdzamy, czy input nie wymaga przedluzenia

    mov rax, rsi        ; Sprawdzamy ilosc wczytanych znakow
    sub rax, input_buffer

    cmp rax, r8         ; Jesli rowna ilosci znakow z inputu
    je read             ; Wczytaj ponownie

    jmp convert_text_loop


digit_to_morse:
    sub al, '0'         ; Od cyfry (char) odejmujemy znak '0' aby mieć jej wartość numeryczną
    mov rbx, morse_digits
    call set_char_d
    mov rcx, 0          ; Zerujemu RCX, będzie indexem do pętli
    jmp write_digit_loop

set_char_d:             ; Ustawiamy wskaźnik na kody morsa dla cyfr tak aby był na
    cmp al, 0           ; początku odpowiadającego kodu
    jne add_five        
    ret

add_five:               ; Zwiększamy wskaźnik o 5, bo każdy kod morse'a dla cyfr ma 5 znaków
    add rbx, DIGIT_SIZE          ; Dopóki nie wejdziemy na odpowiedni znak
    dec al              ; Operację wykonujemy AL razy, gdzie AL to pozycja znaku w alfabecie - 1
    jmp set_char_d

write_digit_loop:       ; Po wejściu na dobry kod,  spisujemy do wyjścia 5 kolejnych znaków
    cmp rcx, DIGIT_SIZE          ; Czyli pożądany kod morse'a
    je  add_space
    mov al, byte[rbx]
    mov byte[rdi], al
    inc rdi             ; Przechodzimy na kolejne miejsce w Outpucie
    inc rbx             ; Bierzemy kolejny znak z morse_digits
    inc rcx             ; RCX jest indexem
    jmp write_digit_loop


letter_to_morse:
    sub al, 'A'             ; Od litery odejmujemy znak 'A' aby mieć jej kolejność z alfabetu
    mov rbx, morse_letters  ; Ustawiamy wskaźniki: na znaki dla RBX, na długości dla R9
    mov r9, morse_lenghts

    call set_char_l
    mov cl, 0           ; Zerujemy cl (nie RCX, aby nie było problemu z przekazaniem bajtowej wartości [r9])
    jmp write_letter_loop  

set_char_l:
    cmp al, 0           ; Przesuwamy wskaźnik rbx o tyle w prawo korzystając z długości danych znaków
    jne add_len         ; Robimy to al razy, aby rbx wskazywał na pierwszy znak odpowiedniego kodu morse'a
    ret

add_len:
    xor rdx, rdx        ; Zerujemy rdx, aby pozbyć się poprzednich wartości
    mov dl, byte[r9]    ; Do przejęcia bajtowej długości znaków używamy dl, bo rdx jest zbyt duży
    add rbx, rdx        ; Zwiększamy wskaznik na tablice znakow o dlugosc aktualnego znaku
    inc r9              ; Przechodzimy na kolejna dlugosc znaku
    dec al
    jmp set_char_l

write_letter_loop:
    cmp cl, byte[r9]    ; Dopóki cl jest mniejszy niż bajtowa długość szukanego znaku
    je add_space
    mov al, byte[rbx]   ; Dodajemy do wyjścia kolejne znaki odpowiedniego symbolu morse'a
    mov byte[rdi], al
    inc rdi             ; Przechodzimy na kolejną pozycję outputu
    inc rbx             ; Przesuwamy wskaznik na kod morse'a na prawo
    inc cl              ; Cl to index
    jmp write_letter_loop

write:  ;wypisanie na nowo ; Zachowujemy wartosc wejscia
    mov r12, rsi

    mov rdx, rdi  ; Obliczamy długość outputu poprzez odjęcie od wskaźnika rdi wskaźnika na output
    sub rdx, output_buffer            ; (Rdi był przesuwany w prawo po dodaniu każdego znaku, a przesunięcie w prawo to dodanie 1 do adresu)

    mov rax, SYS_WRITE      
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall 

    test rax, rax           ; Sprawdzamy poprawnosc funkcji 
    js error_exit

    mov rdi, output_buffer  ; przepisujemy wartosci rdi i rsi (output, input)
    mov rsi, r12
    jmp next

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;ZAMIANA Z KODU MORSE'A NA ALFABET
;rsi - wskaznik na pierwszy znaku inputu (inny niz spacja), rdi - wskaznik na pierwsze miejsce outputu, r9 - pomocniczy wskaznik na input (do obserwacji nastepnego kodu)
;r12b - licznik dlugosci kodu, rbx - wskaznik na poczatek kodu morse'a, rcx - licznik dlugosci kodu, r13 - wskaznik porownujacy dany kod morse'a z mozliwymi
;r10 - wskaznik na cyfry lub litery rzeczywiste, al - znak z inputu, dl - znak ze sprawdzanego kodu morse'a, r11 - wskaznik na dlugosci liter w morse'ie, r8 - ilosc wczytanych znakow
read_m:
    mov r10, rdi                ; Zapamietujemy output

    mov rax, SYS_READ 
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, BUFFER_SIZE
    syscall 
    
    mov rdi, r10                ; Przywracamy output

    test rax, rax               ; Test poprawnosci funkcji systemowej
    js error_exit
    je done

    mov r8, rax                 ; Przenosimy ilosc wczytanych bajtow do r8
    cmp r9, single_morse        ; Sprawdzamy czy bylismy w trakcie zapisywania znaku
    jne get_len                 ; Jesli tak, to zapisujemy dalej
    jmp decode_morse
    
decode_morse:
    cmp byte[rsi], 0            ; Jesli kolejny znak jest NULL'em, to konczymy zamiane
    je done    
    cmp byte[rsi], ' '          ; Jesli znak jest dodatkową spacją to ją przepisujemy
    je space_m
    mov r9, single_morse        ; Przenosimy pointer dla znaku morse'a do r9, żeby sprawdzic kolejne znaki
    xor r12, r12
    jmp get_len
space_m:
    mov byte[rdi], ' '          ; Wypisz spacje na output
    jmp check1                  ; Przejdz do sprawdzania czy nie wykracz input lub output

get_len:
    cmp r12b, MAX_CODE_SIZE     ; Sprawdzamy czy kolejny kod przekroczyl dlugosc maksymalna (6: maksymalna dlugosc kodu + spacja)
    je error_exit
    cmp byte[rsi], ' '          ; Jesli kolejny sprawdzany znak to spacja, to mamy koniec danego kodu
    je check_l_len

    xor rax, rax
    mov al, byte[rsi]           ; Spisujemy Znak z inputu do single_morse
    mov byte[r9], al
    inc rsi
    inc r9
    
    mov rax, rsi
    sub rax, input_buffer       ; Sprawdzamy czy ilosc wczytanych znakow jest rowna ilosc znakow na wejsciu
    cmp rax, r8
    je read_m                   ; Jesli tak, to ponownie czytamy inputs

    inc r12b                    ; Zwiekszamy licznik dlugosci znaku
    jmp get_len

check_l_len:
    mov rax, r9
    sub rax, single_morse   ; Różnica r9 i single_morse to dlugosc
    cmp rax, DIGIT_SIZE               ; Jeśli dłuższy niż 5 to źle
    jg error_exit

    cmp rax, DIGIT_SIZE              ; Jesli rowny 5, to cyfra
    je digit_convertion

    jmp letter_convertion   ; Przeciwnie - litera

digit_convertion:
    mov r9, single_morse    ; Przenies wskaznik r9 na poczatek kodu morse'a 
    mov rbx, morse_digits
    mov r13, rbx            ; rbx i r13, to będą wskazniki na kody cyfr

    xor rcx, rcx
    xor rdx, rdx            ; Wyzeruj rejestry pomocnicze
    xor rax, rax

    mov r10, digits         ; Ustaw wskaznik na znaki cyfr

check_d_morse:
    cmp rcx, DIGIT_SIZE     ; Sprawdzamy czy przeszliśmy przez dlugosc cyfry
    je  next_symbol         ; Jeśli tak, to wypisujemy znak
    mov al, byte[r9]
    mov dl, byte[rbx]       ; Porownujemy znaki aktualnego morse'a z inputem
    cmp dl, 0
    je error_exit           ; Jesli dojdziemy do konca mozliwych znakow, to dany znak nie istnieje
    cmp al, dl
    jne go_next_d           ; Jesli znaki nie są identyczne, to sprawdzamy kolejny kod morse'a z mozliwych
    inc r9
    inc rbx                  ; Przejdz do kolejnych znakow inputu, sprawdzanego morse'a
    inc rcx                  ; Zwieksz index długości
    jmp check_d_morse

go_next_d:                  ; Przechodzimy do kolejnego mozliwego znaku morse'a
    je error_exit
    inc r10                 ; Zmieniamy alfabetyczną reprezentacje
    add r13, DIGIT_SIZE     ; Przechodzimy na początek kolejnego znaku morse'a
    mov rbx, r13
    mov r9, single_morse    ; Cofamy wskazniki na poczatki inputu i nowego znaku morse'a
    xor rcx, rcx
    xor rdx, rdx
    xor rax, rax            ; Zerujemy rejestry pomocnicze
    jmp check_d_morse

letter_convertion:          ; Przenies wskaznik r9 na poczatek kodu morse'a z inputu
    mov r9, single_morse

    mov rbx, morse_letters  ;rbx i r13, to będą wskazniki na kody liter
    mov r13, rbx

    mov r11, morse_lenghts  ; Ustawiamy wskaznik na dlugosci liter morse'a

    xor rcx, rcx
    xor rdx, rdx            ; Wyzeruj rejestry pomocnicze
    xor rax, rax

    mov r10, alphabet       ; Ustaw wskaznik na znaki cyfr

check_l_morse:
    cmp byte[r11], 0        ; Jesli doszlismy do konca dlugosci, to nie ma juz innych znakow
    je error_exit
    cmp r12b, byte[r11]     ; r12b zawiera dlugosc znaku morse'a z inputu, jesli nie jest ona rowna
    jne go_next_l           ; dlugosci sprawdzanego znaku, to sprawdzamy kolejny
    cmp cl, byte[r11]       ; Jesli przeszlismy przez cala dlugosc sprawdzanego znaku, to znaki są identyczne i je wypisujemy
    je  next_symbol
    mov al, byte[r9]        ; Umieszczamy w al znak z inputu
    mov dl, byte[rbx]       ; a w dl znak sprawdzanej litery morse'a
    cmp al, dl
    jne go_next_l           ; jesli znaki sa rozne, to sprawdzamy kolejny symbol
    inc r9
    inc rbx                 ; Przejdz do kolejnych znakow, zwieksz index dlugosci
    inc cl
    jmp check_l_morse

go_next_l:
    xor rdx, rdx        ; Czyścimy RDX - posluzy pomocniczo do dodania bajtowej odleglosci do rejestru r8
    inc r10             ; Przechodzimy do kolej reprezentacji znaku (alfabet)
    mov dl, byte[r11]   ; Zwiększamy wskaznik na litery o dlugosc ostatniej litery 
    add r13, rdx
    mov rbx, r13        ; Resetujemy wskazniki sprawdzające na początek wejścia i nowego znaku morse'a
    mov r9, single_morse
    inc r11             ; Przechodzimy na kolejną długość morse'a
    xor rcx, rcx
    xor rdx, rdx
    xor rax, rax        ; Czyścimy rejestry pomocnicze
    jmp check_l_morse

next_symbol:
    mov al, byte[r10]   ; Zapisujemy do al znak który był poprawną literą lub cyfrą
    mov byte[rdi], al   ; Przenosimy ją na output
check1:
    inc rdi             ; Przechodzimy na kolejny znak outputu
    mov rax, rdi        ; Sprawdzamy ilosc wypisanych znakow
    sub rax, output_buffer
    cmp rax, BUFFER_SIZE    ; Jeslii rowna dlugosci wyjscia, to wypisujemy 
    je write_m
check:
    inc rsi             ; Przechodzimy na kolejne miejsce inputu

    mov rax, rsi        ; Sprawdzamy ilosc zczytanych znakow
    sub rax, input_buffer
    cmp rax, r8         ; Jesli jest ich tyle, co znakow na wejsciu, to ponownie wczytujemy
    je read_m

    jmp decode_morse

write_m:

    mov r10, rsi        ; Zapamietujemy input

    sub rdi, output_buffer
    mov rdx, rdi
    mov rax, 1              ;Wypisujemy wynik na standardowe wyjście
    mov rdi, 1
    mov rsi, output_buffer
    syscall

    test rax, rax       ; Test czy wczytanie sie powiodlo
    js error_exit

    mov rdi, output_buffer
    mov rsi, r10        ; Przywracamy input
    jmp check

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;MOZLIWE ZAKONCZENIA PROGRAMU
done:   ; Wypisanie znaków i zakończenie z kodem 0
    sub rdi, output_buffer  ; obliczamy ilosc znakow do wypisania
    mov rdx, rdi            ; Przenosimy ją do rdx, czyli wskazanego rejestru

    mov rax, SYS_WRITE      
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall

    mov rax, SYS_EXIT       ; Program zakonczony sukcesem
    mov rdi, SUCCES_CODE
    syscall


error_exit:  ; Wyjście z programu z kodem error
    mov rax, SYS_EXIT
    mov rdi, ERROR_CODE
    syscall
