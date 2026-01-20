;=====================================================================
;|                             EMU8086                               |                
;=====================================================================             
;| Validasi 16 digit VISA/MASTERCARD                                 |
;| Jika TIDAK VALID -> TIDAK tampilkan data dan meminta input ulang  |
;| Jika VALID -> tampilkan data otomatis + menu cek lagi/keluar      |
;=====================================================================  
                                                            
                                                            
;====================================================================
;|               NOMOR KARTU YANG HARUS DI INPUTKAN                 |
;====================================================================                                      
;| VISA valid: 4111111111111111                                     |
;| MasterCard valid: 5555555555554444                               |
;| Tidak valid (Luhn salah): 4111111111111112                       |
;====================================================================



org 100h
jmp start

; -------------------- DATA --------------------
msgTitle   db 13,10,'=== VALIDASI KARTU KREDIT 16 DIGIT ===',13,10,'$'
msgPrompt  db 13,10,'Masukkan nomor kartu 16 digit : $'
msgBadFmt  db 13,10,'Input salah! Harus 16 digit angka.',13,10,'$'
msgInvalid db 13,10,'Nomor tidak valid! Masukkan nomor yang benar.',13,10,'$'

msgShow    db 13,10,13,10,'--- DATA KARTU (SIMULASI OTOMATIS) ---$'
msgNo      db 13,10,'Nomor   : $'
msgType    db 13,10,'Jenis   : $'
msgExp     db 13,10,'Expiry  : $'
msgCvv     db 13,10,'CVV     : $'
msgName    db 13,10,'Nama    : $'
msgLimit   db 13,10,'Limit   : $'

msgVisa    db 'VISA$'
msgMC      db 'MASTERCARD$'

visaExp    db '12/28$'
mcExp      db '11/29$'
cvvMask    db '***$'
visaName   db 'ALEX $'
mcName     db 'MICHAEL $'
visaLimit  db 'IDR 50,000,000$'
mcLimit    db 'IDR 75,000,000$'

msgValid   db 13,10,13,10,'HASIL: VALID$'
msgMenu    db 13,10,13,10,'Menu:',13,10,'1. Cek kartu lain',13,10,'2. Keluar',13,10,'Pilihan (1/2): $'
msgBye     db 13,10,'Terima Kasih Program selesai.$'

; DOS buffered input
bufCard db 20,0,20 dup(0)

digits   db 16 dup(0)
cardType db 0        ; 1=VISA, 2=MC

; -------------------- CODE --------------------
start:
    mov dx, offset msgTitle
    mov ah, 09h
    int 21h

main_loop:
    call ReadCard16
    jc  main_loop              ; format salah = ulang input

    ; validasi: tipe + luhn
    call DetectType
    jc  invalid_input          ; bukan VISA/MC = dianggap tidak valid

    call LuhnCheck
    jc  invalid_input          ; tidka valid Luhn = dianggap tidak valid

    ; jika VALID = tampilkan data
    call PrintCardDataAuto

    mov dx, offset msgValid
    mov ah, 09h
    int 21h

menu:
    call MenuChoice
    cmp al, '1'
    je  main_loop

    mov dx, offset msgBye
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    int 21h

invalid_input:
    mov dx, offset msgInvalid
    mov ah, 09h
    int 21h
    jmp main_loop

; ==========================================================
; ReadCard16: input harus tepat 16 digit angka
; simpan ke digits[0..15] 
; ==========================================================
ReadCard16 proc
    mov dx, offset msgPrompt
    mov ah, 09h
    int 21h

    mov dx, offset bufCard
    mov ah, 0Ah
    int 21h

    mov al, [bufCard+1]
    cmp al, 16
    jne rc_bad

    lea si, bufCard+2
    mov cx, 16
    xor bx, bx

rc_loop:
    mov al, [si]
    inc si
    cmp al, '0'
    jb  rc_bad
    cmp al, '9'
    ja  rc_bad
    sub al, '0'
    mov [digits+bx], al
    inc bx
    loop rc_loop

    clc
    ret

rc_bad:
    mov dx, offset msgBadFmt
    mov ah, 09h
    int 21h
    stc
    ret
ReadCard16 endp

; ==========================================================
; DetectType:
; VISA: first digit = 4
; MasterCard: 51-55
; CF=1 jika bukan keduanya
; ==========================================================
DetectType proc
    mov byte ptr [cardType], 0

    mov al, [digits+0]
    cmp al, 4
    je  dt_visa

    cmp al, 5
    jne dt_fail
    mov al, [digits+1]
    cmp al, 1
    jb  dt_fail
    cmp al, 5
    ja  dt_fail

    mov byte ptr [cardType], 2
    clc
    ret

dt_visa:
    mov byte ptr [cardType], 1
    clc
    ret

dt_fail:
    stc
    ret
DetectType endp

; ==========================================================
; PrintCardDataAuto: cetak nomor + data otomatis
; (terpanggil HANYA jika VALID)
; ==========================================================
PrintCardDataAuto proc
    mov dx, offset msgShow
    mov ah, 09h
    int 21h

    ; Nomor
    mov dx, offset msgNo
    mov ah, 09h
    int 21h

    mov cx, 16
    mov si, offset digits
p_num:
    mov dl, [si]
    add dl, '0'
    mov ah, 02h
    int 21h
    inc si
    loop p_num

    ; Jenis
    mov dx, offset msgType
    mov ah, 09h
    int 21h
    call PrintTypeOnly

    ; Expiry
    mov dx, offset msgExp
    mov ah, 09h
    int 21h
    call PrintExpiryAuto

    ; CVV (masked)
    mov dx, offset msgCvv
    mov ah, 09h
    int 21h
    mov dx, offset cvvMask
    mov ah, 09h
    int 21h

    ; Nama
    mov dx, offset msgName
    mov ah, 09h
    int 21h
    call PrintNameAuto

    ; Limit
    mov dx, offset msgLimit
    mov ah, 09h
    int 21h
    call PrintLimitAuto

    ret
PrintCardDataAuto endp

PrintTypeOnly proc
    mov al, [cardType]
    cmp al, 1
    je  pto_visa
    mov dx, offset msgMC
    jmp pto_out
pto_visa:
    mov dx, offset msgVisa
pto_out:
    mov ah, 09h
    int 21h
    ret
PrintTypeOnly endp

PrintExpiryAuto proc
    mov al, [cardType]
    cmp al, 1
    je  pea_visa
    mov dx, offset mcExp
    jmp pea_out
pea_visa:
    mov dx, offset visaExp
pea_out:
    mov ah, 09h
    int 21h
    ret
PrintExpiryAuto endp

PrintNameAuto proc
    mov al, [cardType]
    cmp al, 1
    je  pna_visa
    mov dx, offset mcName
    jmp pna_out
pna_visa:
    mov dx, offset visaName
pna_out:
    mov ah, 09h
    int 21h
    ret
PrintNameAuto endp

PrintLimitAuto proc
    mov al, [cardType]
    cmp al, 1
    je  pla_visa
    mov dx, offset mcLimit
    jmp pla_out
pla_visa:
    mov dx, offset visaLimit
pla_out:
    mov ah, 09h
    int 21h
    ret
PrintLimitAuto endp

; ==========================================================
; LuhnCheck: CF=0 valid, CF=1 invalid
; ==========================================================
LuhnCheck proc
    xor ax, ax
    mov di, 15
    mov dl, 0

luhn_loop:
    mov bl, [digits+di]
    cmp dl, 0
    je  add_plain

    shl bl, 1
    cmp bl, 9
    jbe add_dbl
    sub bl, 9

add_dbl:
    xor bh, bh
    add ax, bx
    jmp luhn_next

add_plain:
    xor bh, bh
    add ax, bx

luhn_next:
    xor dl, 1
    dec di
    jns luhn_loop

    mov bx, 10
    xor dx, dx
    div bx
    cmp dx, 0
    jne lc_bad
    clc
    ret

lc_bad:
    stc
    ret
LuhnCheck endp

; ==========================================================
; MenuChoice: ulang sampai '1' atau '2', return AL
; ==========================================================
MenuChoice proc
mc_again:
    mov dx, offset msgMenu
    mov ah, 09h
    int 21h

    mov ah, 01h
    int 21h

    cmp al, '1'
    je  mc_ok
    cmp al, '2'
    je  mc_ok
    jmp mc_again
mc_ok:
    ret
MenuChoice endp
