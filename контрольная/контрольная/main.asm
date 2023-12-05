;
; AssemblerProject.asm
;
; Created: 05.12.2023 13:24:53
; Author : vova1
;

.def tmp = R16
.def buf = R17
.def pow = R18
.def spd = R19
.def mod = R20
.def sreg_save = R21
.def tmp2 = R22

.dseg

.cseg

.org $0000
rjmp reset

.org PCI0addr
rjmp PCI0_int_handler

.org OC1Aaddr
rjmp OC1A_int_handler



; Replace with your application code
reset:					ldi tmp, low(RAMEND);инициализация стека
						out SPL, tmp
						ldi tmp, high(RAMEND)
						out SPH, tmp

						ldi tmp, (1<<OCIE1A);инициализация таймера
						sts TIMSK1, tmp
						ldi tmp, (1 << WGM12) | (1 << CS12); таймер по сравнению, прескейлер 1024
						sts TCCR1B, tmp
						ldi tmp, 0x02
						sts OCR1AH, tmp
						ldi tmp, 0x00
						sts OCR1AL, tmp

						;ldi tmp, 0b01111001; инициализация pwm
						;sts TCCR2A, tmp
						;ldi tmp, 190
						;sts OCR2A, tmp
					
						ldi tmp, (1 << PCIE0); инициализация внешнего прерывания PCINT0
						out EIMSK, tmp
						ldi tmp, 0xff
						sts PCMSK0, tmp
						ldi tmp, (1 << ISC00) | (1 << ISC01)
						sts EICRA, tmp

						ldi tmp, 0xff;лампочьки
						out DDRC, tmp
						ldi tmp, (1 << PB7);диод питания
						out DDRB, tmp

						ldi tmp, 0;кнопки
						out DDRE, tmp

						ldi pow, 1; инициализация регистров
						ldi buf, 0
						ldi mod, 2
						ldi spd, 1
						sei

main_loop:				sleep
						rjmp main_loop
				

PCI0_int_handler:		in tmp, SREG
						push tmp
						ldi tmp, 0
						cp tmp, pow
						pop tmp
						out SREG, tmp
						reti

OC1A_int_handler:		in sreg_save, SREG
						ldi tmp, 0
						cp tmp, pow
						breq power_off
power_on:				ldi tmp, 1
						cp mod, tmp
						breq mode_half_blink;режим 1
						brlt mode_flashing;режим 0
						rjmp mode_led_chain;режим 2
						rjmp OC1A_int_handler_end
power_off:				rcall power_led_off
						ldi tmp, 0
						out PORTC, tmp
OC1A_int_handler_end:	out SREG, sreg_save
						reti

mode_flashing:			ldi tmp, 0
						cp tmp, buf
						breq mode_flashing_off
mode_flashing_on:		ldi tmp, 0xff
						ldi buf, 0
						rjmp mode_flashing_end
mode_flashing_off:		ldi tmp, 0
						ldi buf, 1
mode_flashing_end:		out PORTC, tmp
						rjmp OC1A_int_handler_end

mode_half_blink:		ldi tmp, 0
						cp tmp, buf
						breq mode_half_blink_2
mode_half_blink_1:		ldi tmp, 0b01010101
						ldi buf, 0
						rjmp mode_half_blink_end
mode_half_blink_2:		ldi tmp, 0b10101010
						ldi buf, 1
mode_half_blink_end:	out PORTC, tmp
						rjmp OC1A_int_handler_end

mode_led_chain:			ldi tmp2, 1
						mov tmp, buf ; buf -> tmp
led_chain_shift_start:	cpi tmp, 0
						breq led_chain_shift_end
						lsl tmp2
						dec tmp
						rjmp led_chain_shift_start
led_chain_shift_end:	out PORTC, tmp2
						inc buf
						cpi buf, 8
						brne mode_led_chain_end
						ldi buf, 0
mode_led_chain_end:		rjmp OC1A_int_handler_end

power_led_off:			nop
						ret