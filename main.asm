;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------


RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; Registers
;-------------------------------------------------------------------------------
;	- r4 :	- Holds the state of the game. 0 - lost, 1- won, 2- in game, 3- idle state
;			- Only changed in interrupt
;
;	- r5 :	- Holds the difficulty, difficulty increases after each win
;	- r6 :	- Total step size for the current level
;	- r7 :	- Number of steps the player took
;	- r8 :	- array index
;
;-------------------------------------------------------------------------------

    .data
arr: .space 16
	.text

;-------------------------------------------------------------------------------
; SETS
;-------------------------------------------------------------------------------

	bic.b #00011101b, &P2DIR ; Set P2.0, P2.2, P2.3 and P2.4 as Inputs
	bis.b #00011101b, &P2REN ; Enable pull-up/down resistors
	bis.b #00011101b, &P2OUT ; Set as Pull-ups (so button pulls to GND)

	bic.b #01011111b, &P1SEL ; Select Digital I/O for 1.1,
	bic.b #01011111b, &P1SEL2 ; Select Digital I/O for 1.1,
	bis.b #01011111b, &P1DIR ; Selected ports 1.0, 1.1, 1.2, 1.3, 1.6 for output


	bis.b #00011101b, &P2IE ; Enable interrupts for P2.0, P2.2, P2.3 and P2.4
	bis.b #00011101b, &P2IES ; Set interrupt to trigger on Falling Edge (press)
	bic.b #00011101b, &P2IFG ; Clear any accidental flags before starting

	bis.w #GIE, SR

	bis.b #00000001b, &P2IES ;p2.0 interrupts from H to L
	bis.b #00000001b, &P2IE ; enable p2.0 interrupt
	mov.w #0, r5
	jmp Idle

;-------------------------------------------------------------------------------
; REGISTERS RESET
;-------------------------------------------------------------------------------

Reset_All:
	mov.w #3, r4
	and.w #3, r5
	clr.w r6
	clr.w r7
	clr.w r8
	bic.b #01011110b, &P1OUT	;Turns off all the lights beside the built-in green light
	bic.b #00011101b, &P2IFG
	ret

;-------------------------------------------------------------------------------
; IDLE STATE
;-------------------------------------------------------------------------------
; Labels: Idle, Idle_Exit, both of them wait an interrupt to change r4
;
; Subroutines: Delay_Idle, uses r4 to break early, changes r12 constantly
;-------------------------------------------------------------------------------
Idle:
	call #Reset_All
    xor.b #00010000b, &P1OUT
    call #Delay_Idle
    xor.b #00011000b, &P1OUT
    call #Delay_Idle
    xor.b #00001100b, &P1OUT
    call #Delay_Idle
    xor.b #00000110b, &P1OUT
    call #Delay_Idle
    bic.b #00000010b, &P1OUT
    cmp.w #3,r4
    jeq Idle

Idle_Exit:
    bic.b #00011110b, &P1OUT	;Turns off all the leds
    cmp.w #2, r4
    jeq Level_1
    cmp.w #4, r4
	bic.b #BIT0, &P1OUT			;Turns off the built-in green light
	jmp Idle

Delay_Idle:
    mov.w #0xFFFF, r12
dloop_idle:
    cmp.w #3, r4
    jne d_exit
    sub.w #1, r12
    jne dloop_idle
d_exit:
    ret

;-------------------------------------------------------------------------------
; IN GAME
;-------------------------------------------------------------------------------
; Labels: Level_1, Level_2, Level_3, loop1, loop2, loop3, Lost
;
; Subroutines: Create_Pattern
;-------------------------------------------------------------------------------
Generate_Random:
    mov.w   &TA0R, r10     ; timer value
    and.w   #0x0003, r10   ; between 0-3
    ret

Create_Pattern:
	clr.w r15
cp_loop:
	call #Delay_Difficult
	mov.w r15, r13
	rla.w r13
	mov.w arr(r13), r14
	inc.w r15

	cmp.w #0,r14
	jeq led1

	cmp.w #1,r14
	jeq led2

	cmp.w #2,r14
	jeq led3

	cmp.w #3,r14
	jeq led4
cp_cont:
	call #Delay_Difficult
	bic.b #00011110b, &P1OUT
	cmp.w r6, r15
	jl cp_loop
	ret

Fill_Pattern:
    clr.w   r15            ; index = 0
fp_loop:
    call    #Generate_Random
    mov.w   r10, arr(r15)  ; arr[i] = random
    inc.w   r15
    cmp.w   #16, r15  	;until 16 random numbers between 0-3 are generated
    jl      fp_loop
    ret
;-------------------------------------------------------------------------------

Delay:
	mov.w #0xFFFF, r12
dloop:			;0.209 second
	sub.w #1, r12
	jne dloop
	ret

Delay_Difficult: ;for leds to flash faster every 3 level sequences the player wins
	mov.w #5, r11
	sub.w r5, r11
ddloop:
	call #Delay
	dec.w r11
	jne ddloop
	ret

TwoSec_Delay:			;For win state
	mov.w #10, r11
tsdloop:
	call #Delay
	dec.w r11
	jne tsdloop
	ret

;-------------------------------------------------------------------------------
Level_1:

    bic.w   #CCIE, &TA0CCTL0   ; Timer interrupt OFF
	bic.w   #MC_3, &TA0CTL    ; Timer STOP
    bis.w   #CCIE, &TA0CCTL0   ; Timer interrupt On
	bis.w   #MC_3, &TA0CTL    ; Timer Start
	mov.w #2, r6
	add.w r5, r6

	call #Fill_Pattern
	call #Create_Pattern
	clr.w r7
	clr.w r8
loop1:
	cmp.w #2, r4
	jeq loop1

	cmp.w #0, r4
	jeq Lost

	call #Won
	bic.b #BIT6, &P1OUT

;-------------------------------------------------------------------------------

Level_2:
	bic.b #BIT0, &P1OUT
	mov.w #2, r4
	mov.w #3, r6		;We increased the # steps by 1
	add.w r5, r6

	call #Fill_Pattern
	call #Create_Pattern
	clr.w r7
	clr.w r8
loop2:
	cmp.w #2, r4
	jeq loop2

	cmp.w #0, r4
	jeq Lost
	call #Won
	bic.b #BIT6, &P1OUT
;-------------------------------------------------------------------------------
Level_3:
	bic.b #BIT0, &P1OUT
	mov.w #2, r4
	mov.w #4, r6
	add.w r5, r6

	call #Fill_Pattern
	call #Create_Pattern
	clr.w r7
	clr.w r8
loop3:
	cmp.w #2, r4
	jeq loop3
	cmp.w #0, r4
	jeq Lost
	call #Won
	inc.w r5		;the difficulty has increased after a win
	jmp Idle
;-------------------------------------------------------------------------------

Lost:
	bis.b #BIT6, &P1OUT
	mov.w #3, r4
	mov.w #10, r11
Lloop:
	xor.b #00011110b, &P1OUT
    call #Delay
	dec.w r11
	jne Lloop

	jmp Idle

Won:
	bis.b #BIT0, &P1OUT
	mov.w #2, r4
	call #TwoSec_Delay
	ret
;-------------------------------------------------------------------------------

led1:
	bis.b #BIT1,&P1OUT
	jmp cp_cont
led2:
	bis.b #BIT2,&P1OUT
	jmp cp_cont
led3:
	bis.b #BIT3,&P1OUT
	jmp cp_cont
led4:
	bis.b #BIT4,&P1OUT
	jmp cp_cont

;-------------------------------------------------------------------------------
; INTERRUPT
;-------------------------------------------------------------------------------

press_ISR:
	cmp.w #2, r4 ;if r4 == 2, then the player is in the game
	jeq in_Game

	cmp.w #3, r4 ;if r4 == 3, then the player is in idle state
	jeq in_idle

	jmp return

in_idle:
    bit.b #BIT0, &P2IFG
    jeq return

    bit.b #BIT0, &P2IES
    jnz button_Pressed
    jmp button_Released

start_game:
    mov.w #2, r4
    jmp return


;-------------------------------------------------------------------------------

in_Game:
    bit.b #BIT0, &P2IFG
    jne button1_pressed

    bit.b #BIT2, &P2IFG
    jne button2_pressed

    bit.b #BIT3, &P2IFG
    jne button3_pressed

    bit.b #BIT4, &P2IFG
    jne button4_pressed

    reti

button1_pressed:
	cmp.w #0, arr(r8)
	jne lose
	jmp win_check

button2_pressed:
	cmp.w #1, arr(r8)
	jne lose
	jmp win_check

button3_pressed:
	cmp.w #2, arr(r8)
	jne lose
	jmp win_check

button4_pressed:
	cmp.w #3,arr(r8)
	jeq win_check

;-------------------------------------------------------------------------------

lose:
	mov.w #0, r4
	jmp return

win_check:
	inc.w r7
	mov.w r7, r8
	rla.w r8
	cmp.w r6, r7 	;check if array is finished
	jl return
	mov.w #1, r4 	;if finished r4=1 (win state)

;-------------------------------------------------------------------------------

return: 			;Clears the interrupt state before returning
	bic.b #00011101b, &P2IFG
	reti

;-------------------------------------------------------------------------------

button_Pressed:
    mov.w   #0xFFFF, &TA0CCR0
    mov.w   #TASSEL_1 | MC_2, &TA0CTL ; ACLK, Continuous Mode
    bis.w   #CCIE, &TA0CCTL0        ; Turn on timer interrupt

    bic.b   #BIT0, &P2IES

    jmp return

button_Released:
    bis.w #TACLR,&TA0CTL
    bic.w   #CCIE, &TA0CCTL0        ; Turn off timer interrupt
    bis.b   #BIT0, &P2IES           ; Wait for Falling Edge (Press) again
    jmp return

timer_ISR:
    bis.w #TACLR,&TA0CTL
    bic.w   #CCIE, &TA0CCTL0

    mov.w   #2, r4
    bic.w   #LPM3, 0(SP)
    reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect ".int03" 			; Port 2 interrupt vector
			.short press_ISR
            .sect   ".reset"        ; MSP430 RESET Vector
            .short  RESET
            .sect ".int09"          ; Timer0_A0
			.short timer_ISR
