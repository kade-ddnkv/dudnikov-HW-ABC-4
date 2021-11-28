;------------------------------------------------------------------------------
; heapsort.asm - единица компиляции, вбирающая функции для пирамидальной сортировки
;------------------------------------------------------------------------------

extern stdout
extern fprintf

extern MaxDistanceTransport

;----------------------------------------------
; Заполнение массива ключей (для каждого транспорта ключ - его максимальная дистанция)
; Эквивалентно циклу
;for (int i = 0; i < c.len; ++i) {
;    keys[i] = maxDistance(*c.data[i]);
;}
global FillKeysArray
FillKeysArray:
section .data
    .sum    dq  0.0
section .bss
	keys 	  resq	 10000 	; Массив ключей (double max_distance для 10000 элементов)
section .text
enter 0, 0

    ; В rdi адрес начала контейнера
    ; В esi количество объектов

    mov ebx, esi            ; число фигур
    xor ecx, ecx            ; счетчик фигур
    ;mov r11, keys			; сохранение начала ключа
    ;mov .keyPtr, keys

    ; Заполнение массива ключей
.loop:
    cmp ecx, ebx            ; проверка на окончание цикла
    jge .return             ; Перебрали все фигуры

    mov r10, rdi            ; сохранение начала фигуры
    call MaxDistanceTransport     ; Получение периметра первой фигуры в xmm0

    movsd [keys+8*rcx], xmm0    ; сохранение ключа
    inc ecx                 ; индекс следующей фигуры
    add r10, 20             ; адрес следующей фигуры
    mov rdi, r10            ; восстановление для передачи параметра
    jmp .loop

.return:
	mov rdx, keys
leave
ret


;----------------------------------------------
; Делает своп двух ключей (double) по их адресам
global SwapKey
SwapKey:
section .bss
	.tmp 	resq 	1
section .text
enter 0, 0

    ; В rdi лежит адрес левого объекта
    ; В rsi лежит адрес правого объекта

    movsd xmm0, [rdi]
    movsd xmm1, [rsi]
    movsd [rsi], xmm0
    movsd [rdi], xmm1

.return:
leave
ret

;----------------------------------------------
; Делает своп двух транспортов (по 20 байт в каждом) по их адресам
global SwapTransport
SwapTransport:
section .bss
	.cont 	resd 	1
	.tmp 	resb 	20
section .text
enter 0, 0

    ; В rdi лежит адрес левого объекта
    ; В rsi лежит адрес правого объекта
    ;mov [.cont], rdi

    ; Регистры rax, r9, r10 свободны

    mov r9d,	[rdi]			; копирование ключа (int)
    mov r10d,	[rsi]
    mov [rdi],	r10d
    mov [rsi],	r9d
    add rdi, 4
    add rsi, 4

    mov r9d,	[rdi]		; копирование 1 (int)
    mov r10d,	[rsi]
    mov [rdi],	r10d
    mov [rsi],	r9d
    add rdi, 4
    add rsi, 4

    movsd xmm0,		[rdi]		; копирование 2 (double)
    movsd xmm1,		[rsi]
    movsd [rdi],	xmm1
    movsd [rsi],	xmm0
    add rdi, 8
    add rsi, 8

    mov r9d,	[rdi]	; копирование 3 (int)
    mov r10d,	[rsi]
    mov [rdi],	r10d
    mov [rsi],	r9d

.return:
leave
ret


;----------------------------------------------
;// Вспомогательный метод. Его применение предполагает, что ему дается мин-куча, где только корень нарушает структуру.
;// Метод за O(log2(кол-во элементов дереве)) последовательными свопами перемещает корень в нужное место в мин-куче.
;void heapify(road_transport **data, double *keys, const int &len, int root) {
;    int smallest = root;
;    int l = root * 2 + 1;
;    int r = root * 2 + 2;
;
;    if (l < len && keys[l] < keys[smallest]) {
;        smallest = l;
;    }
;    if (r < len && keys[r] < keys[smallest]) {
;        smallest = r;
;    }
;
;    if (root != smallest) {
;        std::swap(keys[root], keys[smallest]);
;        std::swap(data[root], data[smallest]);
;        heapify(data, keys, len, smallest);
;    }
;}
global Heapify
Heapify:
section .bss
	.cont 	resq 	1 		; Ссылка на адрес начала контейнера
	.len 	resd 	1 		; Ссылка на количество объектов
	.keys 	resq 	1 		; Ссылка на адрес начала массива ключей
section .text
enter 0, 0

    ; В rdi адрес начала контейнера (data)
    ; В esi количество объектов (len)
    ; В rdx адрес начала массива ключей (keys)
    ; В r8d индекс текущего узла дерева (root)
    ; rcx и rbx не трогать! - в них лежит внешний цикл
    
    ; left будет лежать в r9
    ; right будет лежать в r10
    ; smallest будет лежать в r11
    mov r11d, r8d
    mov r9d, r8d
    add r9d, r8d
    add r9d, 1
    mov r10d, r8d
    add r10d, r8d
    add r10d, 2


    ; Первый иф
    cmp r9d, esi
    jl .leftSubIf
    jge .rightIf

.leftSubIf:
    mov rax, [rdx+8*r9]
    cmp rax, [rdx+8*r11]
    jge .rightIf
    mov r11d, r9d

.rightIf:
    cmp r10d, esi
    jl .rightSubIf
    jge .lastIf

.rightSubIf:
    mov rax, [rdx+8*r10]
    cmp rax, [rdx+8*r11]
    jge .lastIf
    mov r11d, r10d

.lastIf:
    cmp r8d, r11d
    je .return
    ; Два swap (для ключей и для объектов)
    ; Сохранение rdi и esi перед swap
    mov [.cont], rdi
    mov [.len], esi
    mov [.keys], rdx
    lea rdi, [rdx+8*r8]
    lea rsi, [rdx+8*r11]
    call SwapKey
    ; Умножение задействует rax и rdx
    mov edx, 0
    mov eax, r8d
    mov esi, 20
    mul esi ; результат в ax
    add eax, [.cont]
    mov rdi, rax

    mov edx, 0
    mov eax, r11d
    mov esi, 20
    mul esi ; результат в ax
    add eax, [.cont]
    mov rsi, rax
    call SwapTransport
    
    ; Вызвать Heapify рекурсивно
    mov rdi, [.cont]
    mov esi, [.len]
    mov rdx, [.keys]
    mov r8, r11
    call Heapify

.return:
leave
ret



;----------------------------------------------
;void heapSort(container &c) {
;    double keys[c.len];
;    for (int i = 0; i < c.len; ++i) {
;        keys[i] = maxDistance(*c.data[i]);
;    }
;
;    // В начале нужно создать из неструктурированного массива мин-кучу.
;    // Эта операция похожа на индукцию.
;    // Начинаю запускать с нижних поддеревьев из трех элементов (база).
;    // На всех следующих элементах оказывается, что два поддерева у корня являются мин-кучами (шаг индукции)
;    // И только корень поддерева нарушает структуру, поэтому применяется heapify.
;    for (int i = c.len / 2 - 1; i >= 0; --i) {
;        heapify(c.data, keys, c.len, i);
;    }
;
;    // Для создания отсортированного массива
;    // Каждый раз убираем корень дерева и ставим на его место последний элемент мин-кучи.
;    // После чего применяем heapify, чтобы опять наверху оказался минимальный элемент.
;    for (int i = c.len - 1; i >= 0; --i) {
;        std::swap(c.data[0], c.data[i]);
;        std::swap(keys[0], keys[i]);
;        // Применение heapify опускает корневой элемент ниже по дереву до подходящего места.
;        heapify(c.data, keys, i, 0);
;    }
;}
global HeapSortContainer
HeapSortContainer:
section .data
    .sum    dq  0.0
	debugPoint1	db 	"DEBUG POINT 1", 10, 0
	debugPoint2	db 	"DEBUG POINT 2", 10, 0
	debugPoint3	db 	"DEBUG POINT 3", 10, 0
section .bss
	.cont 	resq 	1 		; Ссылка на адрес начала контейнера
	.len 	resd 	1 		; Количество объектов
	.keys 	resq 	1 		; Ссылка на адрес начала массива ключей
section .text
enter 0, 0

    ; В rdi адрес начала контейнера
    ; В esi количество объектов
    mov [.cont], rdi
    mov [.len], esi

    call FillKeysArray

    ; В rdx адрес начала массива ключей
    mov [.keys], rdx

    mov ebx, 0              ; правая граница для цикла

    mov edx, 0  			; для деления
    mov eax, [.len]			
    mov ecx, 2
    div ecx					; частное от деления на 2 в rax
    dec eax                 ; вычитание 1
    mov ecx, eax            ; rcx - это счетчик фигур = len / 2 - 1

.loopCreateMinHeap:
    ; DEBUG POINT 1
    ;mov rdi, [stdout]
    ;mov rsi, debugPoint1
    ;;mov rdx, rcx ; первый аргумент для строки fprintf
    ;mov rax, 0
    ;call fprintf

    cmp ecx, ebx			; проверка на окончание цикла
    jl .beforeSort
    
    mov rdi, [.cont]
    mov esi, [.len]
    mov rdx, [.keys]
    mov r8d, ecx
    call Heapify
    dec rcx					; индекс следующей фигуры
    jmp .loopCreateMinHeap

.beforeSort:
    mov ecx, [.len] 		; ecx - левая граница
    dec ecx
    mov ebx, 0 				; ebx - правая граница

.loopSort:
    cmp ecx, ebx
    jle .return

    ; Скопировано из метода Heapify.
    
    mov rdx, [.keys] 		; восстановление массива ключей

    ; Два swap (для ключей и для объектов)

    lea rdi, [rdx]
    lea rsi, [rdx+8*rcx]
    call SwapKey

    ; Умножение задействует rax и rdx
    mov edx, 0 				; data[i] - это [[.cont] + 20*ecx]
    mov eax, ecx
    mov esi, 20
    mul esi ; результат в ax
    add eax, [.cont]
    mov rsi, rax

    mov rdi, [.cont]
    call SwapTransport

    ; Вызвать Heapify
    mov rdi, [.cont]
    mov esi, ecx
    mov rdx, [.keys]
    mov r8, 0
    call Heapify

   	dec ecx
    jmp .loopSort


.return:
leave
ret


