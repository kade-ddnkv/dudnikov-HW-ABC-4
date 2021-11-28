;------------------------------------------------------------------------------
; perimeter.asm - единица компиляции, вбирающая функции вычисления периметра
;------------------------------------------------------------------------------

extern TRUCK
extern BUS
extern CAR

;----------------------------------------------
; Вычисление максимальной дистанции транспорта
; Пример для truck:
;double maxDistance(truck &t) {
;    return t.fuel_tank_capacity / (t.fuel_consumption / 100);
;}
global MaxDistanceTransport
MaxDistanceTransport:
section .data
    .oneHundredDouble  dq      100.0
section .text
enter 0, 0

    ; Для всех транспортов вычисление максимальной дистанции одинаковое

    ; В rdi адрес транспорта
    add     rdi, 4

    ; = fuel_tank_capacity / (fuel_consumption / 100)
    ; = fuel_tank_capacity / fuel_consumption * 100

    cvtsi2sd xmm0, [rdi]
    movsd    xmm1, [rdi+4]
    divsd    xmm0, xmm1
    mulsd    xmm0, [.oneHundredDouble]
    ; Теперь в xmm0 лежит max_distance

return:
leave
ret