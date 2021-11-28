;------------------------------------------------------------------------------
; output.asm - единица компиляции, вбирающая функции для вывода транспорта на консоль / в файл
;------------------------------------------------------------------------------

extern printf
extern fprintf

extern MaxDistanceTransport

extern TRUCK
extern BUS
extern CAR

; Функции вывода в таблицу в C++ программе:
; Они +- реализованы на ассемблере.
;
;void printWithTableView(const std::string &type, const double &max_distance,
;                        const int &fuel_tank_capacity, const double &fuel_consumption,
;                        const std::string &additional_info, const int &additional_result, std::ofstream &ofst) {
;    ofst << std::left << std::setw(7) << type
;         << std::setw(16) << max_distance
;         << std::setw(14) << fuel_tank_capacity
;         << std::setw(14) << std::setprecision(2) << fuel_consumption
;         << std::setw(15) << additional_info
;         << std::setw(10) << additional_result;
;}
;
;void printHeader(std::ofstream &ofst) {
;    ofst << std::left << std::setw(7) << "TYPE"
;         << std::setw(16) << "MAX_DISTANCE"
;         << std::setw(14) << "FUEL_CAP"
;         << std::setw(14) << "FUEL_CONS"
;         << std::setw(25) << "ADDITIONAL_INFO" << "\n";
;}
;
;void printTitle(const std::string &title, std::ofstream &ofst) {
;    ofst << std::string(50, '-')
;         << "\n" << title << "\n"
;         << std::string(50, '-')
;         << "\n";
;}

;----------------------------------------------
; Вывод параметров грузовика в файл
; Пример вывода:
;TYPE   MAX_DISTANCE    FUEL_CAP      FUEL_CONS     ADDITIONAL_INFO          
;truck  6.2e-298        600885778     9.7e+307      load_cap       179455759 
;bus    1.2e-297        1104063831    8.9e+307      passenger_cap  12967     
;car    1.6e-297        1252133626    8.1e+307      max_speed      19260        


;----------------------------------------------
; Вывод заголовка
global OutHeader
OutHeader:
section .data
    .outfmt db "TYPE   MAX_DISTANCE    FUEL_CAP      FUEL_CONS     ADDITIONAL_INFO          ",10,0
section .text
enter 0, 0

    ; В rdi хранится указатель на файл для вывода
    mov     rsi, .outfmt
    call    fprintf

leave
ret

;----------------------------------------------
; Вывод параметров транспорта в файл (в табличном виде)    
global OutTable
OutTable:
section .data
    .outfmt db "%-7s%-16.2f%-14d%-14.2f%-15s%-10d",10,0
    .truckType      db "truck",0
    .busType        db "bus",0
    .carType        db "car",0
    .truckAddInfo   db "load_cap",0
    .busAddInfo     db "passenger_cap",0
    .carAddInfo     db "max_speed",0
section .bss
    .ptrans resq  1
    .FILE   resq  1       ; временное хранение указателя на файл
    .p      resq  1       ; вычисленный периметр
section .text
enter 0, 0

    ; Сохранение принятых аргументов
    mov     [.ptrans], rdi        ; сохраняется адрес транспорта
    mov     [.FILE], rsi          ; сохраняется указатель на файл

    mov rax, [rdi]
    cmp eax, [TRUCK]
    je .truckParams
    cmp eax, [BUS]
    je .busParams
    cmp eax, [CAR]
    je .carParams

    ; Распределение параметров:
    ; rdi  - файл
    ; rsi  - строка формата
    ; rdx  - тип транспорта
    ; xmm0 - максимальная дистанция транспорта
    ; rcx  - fuel_cap
    ; xmm1 - fuel_cons
    ; r8   - add_info_text
    ; r9   - add_info_number

.truckParams:
    mov rdx, .truckType
    mov r8, .truckAddInfo
    jmp .output
.busParams:
    mov rdx, .busType
    mov r8, .busAddInfo
    jmp .output
.carParams:
    mov rdx, .carType
    mov r8, .carAddInfo
    jmp .output

.output:
    ; Вычисление периметра (адрес транспорта уже в rdi)
    call    MaxDistanceTransport
    ; max_distance теперь в xmm0, что и нужно

    ; Заполнение параметров для fprintf
    mov     rdi, [.FILE]
    mov     rsi, .outfmt
    mov     rax, [.ptrans]
    add     rax, 4
    mov     rcx, [rax]
    movsd   xmm1, [rax+4]
    mov     r9, [rax+12]

    mov     rax, 2              ; есть 2 числа с плавающей точкой
    call    fprintf

leave
ret

;----------------------------------------------
; Вывод параметров текущего транспорта в файл
global OutTransport
OutTransport:
section .text
enter 0, 0

    ; Раньше в этом методе была логика, 
    ; но теперь он оставлен на всякий случай,
    ; вдруг понадобится что-то добавить 
    call OutTable
    
return:
leave
ret

;----------------------------------------------
; Вывод содержимого контейнера в файл
global OutContainer
OutContainer:
section .data
    numFmt  db  "%d: ",0
section .bss
    .pcont  resq    1   ; адрес контейнера
    .len    resd    1   ; число введенных элементов
    .FILE   resq    1   ; указатель на файл
section .text
enter 0, 0

    mov [.pcont], rdi       ; сохраняется указатель на контейнер
    mov [.len],   esi       ; сохраняется число элементов
    mov [.FILE],  rdx       ; сохраняется указатель на файл

    ; Вывод заголовка
    mov rdi, [.FILE]
    call OutHeader

    ; В rdi адрес начала контейнера
    mov rbx, [.len]         ; число объектов
    xor ecx, ecx            ; счетчик объектов = 0
    mov rsi, rdx            ; перенос указателя на файл
.loop:
    cmp ecx, ebx            ; проверка на окончание цикла
    jge .return             ; перебрали все объекты

    push rbx
    push rcx

    ; Вывод номера объекта [не нужен]
    ;mov     rdi, [.FILE]    ; текущий указатель на файл
    ;mov     rsi, numFmt     ; формат для вывода объекта
    ;mov     edx, ecx        ; индекс текущей объекта
    ;xor     rax, rax,       ; только целочисленные регистры
    ;call fprintf

    ; Вывод текущей объекта
    mov     rdi, [.pcont]
    mov     rsi, [.FILE]
    call OutTransport

    pop rcx
    pop rbx
    inc ecx                 ; индекс следующего объекта

    mov     rax, [.pcont]
    add     rax, 20         ; адрес следующего объекта
    mov     [.pcont], rax
    jmp .loop

.return:
leave
ret

