;=============================
; PROGRAM CONSTANTS
;=============================
SECOND      = 0AH;   ; 10

SP_START    = c7FFH  ; pointer to end of RAM

PORT0       = 30H    ; PORT0 Data Register
DIR0        = 31H    ; PORT0 Direction Register
PORT1       = 40H    ; PORT1 Data Register
DIR1        = 41H    ; PORT1 Direction Register
PORT2       = 60H    ; PORT2 Data Register
DIR2        = 61H    ; PORT2 Direction Register
PORT3       = c0H    ; PORT3 Data Register
DIR3        = c1H    ; PORT3 Direction Register
PORT4       = d0H    ; PORT4 Data Register
DIR4        = d1H    ; PORT4 Direction Register

TIMER_CTRL = e0H    ; address for TIMER0 CONTROL Register
TIMER_PREL = e1H    ; address for TIMER0 PRESCALER Register (low byte)
TIMER_PREH = e2H    ; address for TIMER0 PRESCALER Register (high byte)
; Reserved bit
TIMER_CMPL = e4H    ; address for TIMER0 COMPARE Register (low byte)
TIMER_CMPH = e5H    ; address for TIMER0 COMPARE Register (high byte)
TIMER_CNTL = e6H    ; address for TIMER0 Counter Register (low byte)
TIMER_CNTH = e7H    ; address for TIMER0 Counter Register (high byte)

; TIMER CONTROL REGISTER FIELDS
TIMER_ENABLE      = 1H  ; bit at position 0
TIMER_IRQ_CLEAR   = 2H  ; bit at position 1
TIMER_RESET       = 4H  ; bit at position 2
TIMER_RESTART     = 3H  ; bit at position 2 and 3, IRQ clear and enable

; PORT4 bit positions
INT_TIMER		  =  01H ; 
INT_START		  =  04H ; 
INT_STOP		  =  05H ; 

PORT0_DIRECTION_VAL  = 7FH ; binary: 0111_1111 ; PORT0 Direction value
PORT1_DIRECTION_VAL  = 7FH ; binary: 0111_1111 ; PORT1 Direction value
PORT2_DIRECTION_VAL  = 7FH ; binary: 0111_1111 ; PORT2 Direction value
PORT3_DIRECTION_VAL  = 7FH ; binary: 0111_1111 ; PORT3 Direction value
PORT4_DIRECTION_VAL  = 30H ; binary: 0011_0000 ; PORT4 Direction value

;==============================================
; Initialization Phase
;==============================================
ORG 0000H

; Initialize Stack pointer to top of RAM
LD HL, SP_START
LD SP, HL

LD B, 01H ; boolean like. If true (1) then stop 
LD C, 0H ; counter
LD D, 0H ; seconds
LD E, 0H ; minutes

JP MAIN ; go to main program

MAIN:

; Initialize Port0
LD A, PORT0_DIRECTION_VAL     
OUT (DIR0), A            ; write Data Direction Register

; Initialize Port1
LD A, PORT1_DIRECTION_VAL     
OUT (DIR1), A            ; write Data Direction Register

; Initialize Port2
LD A, PORT2_DIRECTION_VAL     
OUT (DIR2), A            ; write Data Direction Register

; Initialize Port3
LD A, PORT3_DIRECTION_VAL     
OUT (DIR3), A            ; write Data Direction Register

; Initialize Port4
LD A, PORT4_DIRECTION_VAL     
OUT (DIR4), A            ; write Data Direction Register

; -----------------------------------------------------------
; Initialize Timer
; -----------------------------------------------------------
LD A, TIMER_RESET
OUT (TIMER_CTRL), A     ; reset timer

LD A, 10H
OUT (TIMER_PREL), A     ; initialize timer prescaler register low

LD A, 27H
OUT (TIMER_PREH), A     ; initialize timer prescaler register high

LD A, 01H
OUT (TIMER_CMPL), A     ; initialize timer compare register low

LD A, 00H
OUT (TIMER_CMPH), A     ; initialize timer compare register high

LD A, TIMER_ENABLE
OUT (TIMER_CTRL), A     ; enable timer 
					
; -----------------------------------------------------------
; Initialize Z80 Interrupts
; -----------------------------------------------------------
IM 1                    ; interrupt mode 1
EI                      ; enable interrupts

; -----------------------------------------------------------
; while (1);
; -----------------------------------------------------------
MAIN_LOOP:
JP MAIN_LOOP

;==============================================
; Interrupt Service routine at address 38H
;==============================================
ORG 0038H             

; determine interrupt source (either timer or buttons)

; Button Start?
BUT_START:
IN A, (PORT4)         ; read port 0
AND INT_START         ; AND mask with the bit-position which corresponds to Start button
JR   Z, BUT_STOP      ; if zero check if stop button was pressed 

CALL START_ISR        ; else call start button SR  

; Button Stop?
BUT_STOP:             ; read port 0
IN    A, (PORT4)      ; AND with interrupt 1 bit
AND   INT_STOP        ; if zero check if no button was pressed 
JR    Z, TIMER        ; else call stop button SR  

CALL  STOP_ISR        

; TIMER
TIMER:                ; read port 0

LD A, 0H
CP B
JR NZ, FINISH 		  ; if B == 0 

; check if 1 second has passed
LD A, SECOND
INC C 				  ; counter++
CP C 				  ; A - C : if counter == 10 -> 1 second has passed
JR NZ, FINISH 		  ; if A != C finish            
 
CALL  TIMER_ISR        
LD C, 0H

FINISH:
EI                    ; re-enable interrupts
RETI                  ; return from interrupts

;========================================================
; Button START service subroutine
;========================================================

START_ISR:                        

LD B, 0H ; start stopwatch
LD C, 0H ; counter
LD D, 0H ; seconds
LD E, 0H ; minutes
RET                               

;========================================================
; Button STOP service subroutine
;========================================================

STOP_ISR:                          
LD B, 01H ; stop stopwatch

RET                             

;========================================================
; Timer service subroutine
;========================================================

TIMER_ISR:                          

LD C, 0H
INC D 	  ; seconds++
LD A, 3C  ; check for :59
CP D

JR NZ, DRAW ; if A != D do not increase minutes

MIN_UP:
INC E ; increase minutes
LD D, 0H ; set seconds to zero
; checking if 59: 
LD A, 3C
CP E
JR Z, START_ISR ; if A == E reset stopwatch

DRAW:
; run the appropriate OUT instructions so as to show the correct
; values on the seven segment displays
RET 