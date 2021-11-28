;------------------------------------------------------------------------------
; inrnd.asm - единица компиляции, вбирающая функции для создания случайного транспорта
;------------------------------------------------------------------------------

extern printf
extern rand

extern TRUCK
extern BUS
extern CAR


;----------------------------------------------
; Генератор случайных чисел в диапазоне от 1 до 2000
global Random
Random:
section .data
    .i2000           dq     2000 ; верхняя граница для случайного числа (нижняя = 1)
section .text
enter 0, 0

    xor     rax, rax
    call    rand        ; запуск генератора случайных чисел
    xor     rdx, rdx    ; обнуление перед делением
    idiv    qword[.i2000]       ; (/%) -> остаток в rdx
    mov     rax, rdx
    inc     rax         ; в rax число от 1 до 2000

leave
ret

;----------------------------------------------
; Вспомогательный метод. Генерирует случайное число от 0 до 2147483647
global RandomUpperBound
RandomUpperBound:
section .data
    .RAND_MAX       dq      2147483647 ; верхняя граница для случайного числа (нижняя = 1)
section .text
enter 0, 0

    xor     rax, rax    ;
    call    rand        ; запуск генератора случайных чисел
    xor     rdx, rdx    ; обнуление перед делением
    idiv    qword[.RAND_MAX]       ; (/%) -> остаток в rdx
    mov     rax, rdx

leave
ret

;----------------------------------------------
; Генератор случайного вещественного числа в диапазоне от 1 до 2000
global RandomDouble
RandomDouble:
section .data
    .RAND_MAX   dq      2147483647.0 ; Насколько я понимаю, это значение RAND_MAX в компиляторе GCC.
    .d2000      dq      2000.0 ; верхняя граница для случайного числа (нижняя = 1)
    .oneDouble  dq      1.0
section .text
enter 0, 0

    call    RandomUpperBound
    ; сгенерированное число в rax
    cvtsi2sd xmm0, rax
    divsd    xmm0, [.RAND_MAX]  ; после деления в xmm0 число от 0 до 1
    mulsd    xmm0, [.d2000]       ; после умножения в xmm0 число от 0 до .i20
    addsd    xmm0, [.oneDouble]  ; теперь в xmm0 число от 1 до .i20

leave
ret

;----------------------------------------------
; Случайный ввод 3х параметров транспорта
global InRndTransportParams
InRndTransportParams:
section .bss
    .ptrans  resq   1   ; адрес транспорта
section .text
enter 0, 0

    ; В rdi адрес транспорта
    mov     [.ptrans], rdi
    ; Генерация fuel_tank_capacity
    call    Random   ; сгенерированное случайное значение в eax
    mov     rbx, [.ptrans]
    mov     [rbx], eax
    ; Генерация fuel_consumption
    call    RandomDouble
    movsd   [rbx+4], xmm0
    ; Генерация load_capacity
    call    Random
    mov     rbx, [.ptrans]
    mov     [rbx+12], eax

leave
ret

;----------------------------------------------
; Случайный ввод обобщенного транспорта
global InRndTransport
InRndTransport:
section .bss
    .ptrans     resq    1   ; адрес транспорта
section .text
enter 0, 0

    ; В rdi адрес фигуры
    mov [.ptrans], rdi

    ; Формирование признака фигуры
    xor     rax, rax
    call    rand        ; запуск генератора случайных чисел
    
    ; Получение остатка от деления на 2
    xor     edx, edx    ; зануление первого аргумента
    mov     ecx, 3      ; делитель = 2
    div     ecx
    mov     eax, edx    ; остаток лежит в edx (остаток = 0, 1, 2)
    inc     eax         ; +1, теперь в eax (1, 2 или 3)

    mov     rdi, [.ptrans]
    mov     [rdi], eax  ; запись ключа в транспорт

    ; На всякий случай проверка параметра на корректность
    mov rcx, [.ptrans]          ; загрузка адреса начала транспорта
    mov eax, [rcx]              ; и получение прочитанного признака
    cmp eax, 1
    jl .badAttribute
    cmp eax, 3
    jg .badAttribute

    jmp .transportParamsInRnd

.badAttribute:
    xor eax, eax        ; Некорректный признак - обнуление кода возврата
    jmp     .return

.transportParamsInRnd:
    ; Генерация оставшихся 3х параметров транспорта
    add     rdi, 4
    call    InRndTransportParams
    mov     eax, 1      ; код возврата = 1
    jmp     .return

.return:
leave
ret

;----------------------------------------------
; Случайный ввод содержимого контейнера
global InRndContainer
InRndContainer:
section .bss
    .pcont  resq    1   ; адрес контейнера
    .plen   resq    1   ; адрес для сохранения числа введенных элементов
    .size   resd    1   ; число порождаемых элементов
section .text
enter 0, 0

    mov [.pcont], rdi   ; сохраняется указатель на контейнер
    mov [.plen],  rsi    ; сохраняется указатель на длину
    mov [.size], edx    ; сохраняется число порождаемых элементов
    ; В rdi адрес начала контейнера
    xor ebx, ebx        ; число фигур = 0
.loop:
    cmp ebx, edx
    jge     .return
    ; сохранение рабочих регистров
    push rdi
    push rbx
    push rdx

    call InRndTransport     ; ввод фигуры
    cmp rax, 0          ; проверка успешности ввода
    jle .return        ; выход, если признак меньше или равен 0

    pop rdx
    pop rbx
    inc rbx

    pop rdi
    add rdi, 20             ; адрес следующей фигуры

    jmp .loop
.return:
    mov rax, [.plen]    ; перенос указателя на длину
    mov [rax], ebx      ; занесение длины
leave
ret
