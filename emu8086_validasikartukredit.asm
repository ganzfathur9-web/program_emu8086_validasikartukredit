.model small
.stack 100h

.data
welcomeMsg db 13,10,'Selamat Datang Di Aplikasi Validasi Kartu Kredit$'
inputMsg   db 13,10,'Silahkan masukkan nomor kartu kredit anda : $'
validMsg   db 13,10,9,'STATUS : VALID$'
invalidMsg db 13,10,9,'STATUS : TIDAK VALID$'
retryMsg   db 13,10,'Masukkan nomor kartu kredit yang sesuai dan benar$'
lanjutMsg  db 13,10,'Lanjut cek data kartu? (y/n): $'
thanksMsg  db 13,10,'Terima kasih sudah menggunakan aplikasi ini$'

expMsg     db 13,10,9,'Expired : $'
cvvMsg     db 13,10,9,'CVV     : $'
limitMsg  db 13,10,9,'Limit   : $'

; DATA DUMMY
visaExp   dw 1228
visaCvv   dw 123
visaLimit dw 60000

mcExp     dw 1127
mcCvv     dw 456
mcLimit  dw 65000

inputCard db 16 dup(?)

.code
main proc
    mov ax,@data
    mov ds,ax

start:
    lea dx,welcomeMsg
    mov ah,09h
    int 21h

    lea dx,inputMsg
    mov ah,09h
    int 21h

    ; ambil 16 digit (dummy, tidak dicek satu-satu)
    mov cx,16
    lea si,inputCard
read_loop:
    mov ah,01h
    int 21h
    mov [si],al
    inc si
    loop read_loop

    ; valid dummy (anggap selalu valid)
    lea dx,validMsg
    mov ah,09h
    int 21h

    lea dx,lanjutMsg
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h
    cmp al,'y'
    jne selesai

    ; tampilkan data kartu
    lea dx,expMsg
    mov ah,09h
    int 21h
    mov ax,visaExp
    call printNum16

    lea dx,cvvMsg
    mov ah,09h
    int 21h
    mov ax,visaCvv
    call printNum16

    lea dx,limitMsg
    mov ah,09h
    int 21h
    mov ax,visaLimit
    call printNum16

selesai:
    lea dx,thanksMsg
    mov ah,09h
    int 21h

    mov ah,4Ch
    int 21h
main endp

; ===== CETAK ANGKA 16-BIT =====
printNum16 proc
    mov cx,0
    mov bx,10
p1:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne p1
p2:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop p2
    ret
printNum16 endp

end main
