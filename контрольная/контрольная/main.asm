;
; контрольная.asm
;
; Created: 23.11.2023 12:40:46
; Author : vova1
;
.def tmp = R16
.def buf = R17
.def pow = R18
.def spd = R19
.def mod = R20
.def tmp2 = R21


.dseg

.cseg

.org 0
rjmp setup

.org 0x000E; timer 1 comparation A vector
rjmp timer1_handler

.org 0x0004
rjmp buttons_handler

setup:
	ldi tmp, 0b10000000; лапочька питания
	out DDRB, tmp
	ldi tmp, 0xff; гирлянда
	out DDRC, tmp
	ldi tmp, 0b00000111; кнопки
	out DDRE, tmp
	ldi tmp, 0b00010000; PUD bit //подача питания на кнопочьки
	out MCUCR, tmp
timer_init:
	ldi tmp, 0b00000010; OCIE1A (bit 2 - прерывание по сравнению) 
	sts TIMSK1, tmp
	ldi tmp, 0b00001100; CS11 (прескейлер 8) WGM12 (таймер по сравнению)
	sts TCCR1B, tmp
	ldi tmp, 0x00
	sts OCR1AH, tmp
	ldi tmp, 128
	sts OCR1AL, tmp
pwm_init: 
	ldi tmp, 0b01111001; TCCR2A регистр (fast pwm)
	sts TCCR2A, tmp
	ldi tmp, 190
	sts OCR2A, tmp
buttons_init:
	ldi tmp, 0b00010000; включить pcint 0..7
	sts EIMSK, tmp
	ldi tmp, 0b00000111; включить pcint 0..2
	sts PCMSK0, tmp

registres_setup:
	ldi buf, 0
	ldi pow, 0
	ldi spd, 1
	ldi mod, 0
	sei
	rjmp start

; Replace with your application code
start:
	nop
    rjmp start


timer1_handler:
	ldi tmp, 0
	cp buf, tmp
	breq timer_equal ;branch if equal
	ldi tmp, 0xff
	out PORTC, tmp
	ldi buf, 0
	rjmp timer_return
timer_equal:
	ldi tmp, 0x00
	out PORTC, tmp
	ldi buf, 1
timer_return:
	reti; interrupt return
	

buttons_handler:
	// проверка на кнопки
	in tmp, PINE
	//brbc - прыжок на метку если флаг равен нулю,
	bst tmp, 0; бит кнопки питания
	brbc 6, buttons_no_power_proc
	rcall power_button_proc
buttons_no_power_proc:
	bst tmp, 1; бит кнопки режима
	brbc 6, buttons_no_mode_proc
	rcall mode_button_proc
buttons_no_mode_proc:
	bst tmp, 2
	brbc 6, buttons_return
	rcall speed_button_proc
buttons_return:
	reti;


power_button_proc:
	cpi pow, 1
	breq power_button_proc_if
	ldi pow, 1; else
	rjmp power_button_proc_end
power_button_proc_if:
	ldi pow, 0
power_button_proc_end:
	ret

mode_button_proc:
	inc mod
	ldi tmp, 3
	cpse mod, tmp; ComPare Skip Equal 
	ldi mod, 0
	ldi buf, 1
	ret

speed_button_proc:
	inc spd
	ldi tmp, 11
	cpse spd, tmp
	ldi spd, 0
	//пересчет скорости
	mov spd, tmp
	lsr tmp; деление на 2, остаток во флаге С
	brbs 0, speed_button_proc_odd; по флагу С
	ldi tmp2, 0
	rjmp speed_button_proc_odd_after
speed_button_proc_odd:
	ldi tmp2, 128
speed_button_proc_odd_after:
	sts OCR1AL, tmp2
	sts OCR1AH, tmp
	ret