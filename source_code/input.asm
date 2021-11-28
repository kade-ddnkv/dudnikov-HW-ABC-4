;------------------------------------------------------------------------------
; input.asm - единица компиляции, вбирающая функции для ввода транспорта из файлов
;------------------------------------------------------------------------------

extern printf
extern fscanf

extern TRUCK
extern BUS
extern CAR

;----------------------------------------------
; Ввод параметров транспорта из файла
; Для любого транспорта ввод одинаковый, 
; т.к. каждый транспорт занимает 20 байт в памяти 
global InTransportParams
InTransportParams:
section .data
    .infmt db "%d%f%d",0
section .bss
    .FILE       resq    1   ; временное хранение указателя на файл
    .ptrans     resq    1   ; адрес транспорта
    .double     resq    1   ; адрес 
section .text
enter 0, 0

    ; Сохранение принятых аргументов
    mov     [.ptrans], rdi      ; сохраняется адрес объекта
    mov     [.FILE], rsi        ; сохраняется указатель на файл

    ; Ввод 3х параметров через fscanf
    mov     rdi, [.FILE]        ; файл
    mov     rsi, .infmt         ; формат ввода
    mov     rdx, [.ptrans]      ; первый аргумент (int)
    mov     rcx, .double        ; второй аргумент (double)
    mov     r8, [.ptrans]       ; третий аргумент (int)
    add     r8, 12
    mov     rax, 1              ; есть числа с плавающей точкой
    call    fscanf

    ; Перенос вещественного числа внутрь объекта
    mov      rax, [.double]
    movq     xmm2, rax
    unpcklpd xmm2, xmm2
    cvtps2pd xmm0, xmm2
    mov      rax, [.ptrans]
    add      rax, 4
    movq     [rax], xmm0

leave
ret

;----------------------------------------------
; Ввод параметров обобщенной транспорта из файла
global InTransport
InTransport:
section .data
    .tagFormat   db     "%d",0
    .tagOutFmt   db     "Tag is: %d",10,0
section .bss
    .FILE       resq    1   ; временное хранение указателя на файл
    .ptrans     resq    1   ; адрес транспорта
section .text
enter 0, 0

    ; Сохранение принятых аргументов
    mov     [.ptrans], rdi          ; сохраняется адрес транспорта
    mov     [.FILE], rsi            ; сохраняется указатель на файл

    ; Чтение признака транспорта и его обработка
    mov     rdi, [.FILE]
    mov     rsi, .tagFormat
    mov     rdx, [.ptrans]      ; адрес начала транспорта (его признак (1, 2 или 3))
    xor     rax, rax            ; нет чисел с плавающей точкой
    call    fscanf

    ; Тестовый вывод признака транспорта
    ;mov     rdi, .tagOutFmt
    ;mov     rax, [.ptrans]
    ;mov     esi, [rax]
    ;call    printf

    ; если (признак < 1 или признак > 3)
    ; то вернуться и код возврата = 0

    mov rcx, [.ptrans]          ; загрузка адреса начала транспорта
    mov eax, [rcx]              ; и получение прочитанного признака
    cmp eax, 1
    jl .badAttribute
    cmp eax, 3
    jg .badAttribute

    jmp .transportParamsIn

.badAttribute:
    xor eax, eax        ; Некорректный признак - обнуление кода возврата
    jmp     .return

.transportParamsIn:
    ; Ввод оставшихся параметров транспорта (еще 3 штуки).
    mov     rdi, [.ptrans]
    add     rdi, 4
    mov     rsi, [.FILE]
    call    InTransportParams
    mov     rax, 1  ; Код возврата - true
    jmp     .return

.return:
leave
ret

;----------------------------------------------
; Ввод содержимого контейнера из указанного файла
global InContainer
InContainer:
section .bss
    .pcont  resq    1   ; адрес контейнера
    .plen   resq    1   ; адрес для сохранения числа введенных элементов
    .FILE   resq    1   ; указатель на файл
section .text
enter 0, 0

    mov [.pcont], rdi   ; сохраняется указатель на контейнер
    mov [.plen], rsi    ; сохраняется указатель на длину
    mov [.FILE], rdx    ; сохраняется указатель на файл
    ; В rdi адрес начала контейнера
    xor rbx, rbx        ; число фигур = 0
    mov rsi, rdx        ; перенос указателя на файл
.loop:
    ; сохранение рабочих регистров
    push rdi
    push rbx

    mov     rsi, [.FILE]
    mov     rax, 0      ; нет чисел с плавающей точкой
    call    InTransport ; ввод фигуры
    cmp rax, 0          ; проверка успешности ввода
    jle  .return        ; выход, если признак меньше или равен 0

    pop rbx
    inc rbx

    pop rdi
    add rdi, 20         ; адрес следующей фигуры

    jmp .loop
.return:
    mov rax, [.plen]    ; перенос указателя на длину
    mov [rax], ebx      ; занесение длины
leave
ret