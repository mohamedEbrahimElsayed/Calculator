org 00H 


KEYPAD EQU P3 
RO1 BIT P3.7 
RO2 BIT P3.6
RO3 BIT P3.5
RO4 BIT P3.4
C1 BIT P3.0
C2 BIT P3.1
C3 BIT P3.2
C4 BIT P3.3

LCD_PORT EQU P1

ANS_CHECK EQU 27H
TEMP EQU 26H
ANS_VALUE EQU 25H
TEMP_2ND_OP EQU 21H
TEMP_REM EQU 20H

ERROR EQU 16
OVERFLOW EQU 13
NEG EQU 10

RS BIT P2.1
E BIT P2.2

;initilize input and outputs
MOV P1, #00H
CLR RS
CLR E
MOV KEYPAD, #0FH
MOV P0,#00H
ACALL LCD_INIT


ORG 30H
MAIN:
		MOV A,R0 
		CJNE A,#00H,NO_PREV_IN
		ACALL READ_KEY
NO_PREV_IN:
		MOV R1,A
		ACALL CLEAR_COMAND
		ACALL LCD_DATA

		ACALL READ_KEY 
		MOV R2,A
		CJNE R2,#2FH,CONT_GET1
		SJMP NO_2ND_DIG
CONT_GET1:
		JC NO_2ND_DIG
		ACALL CLEAR_COMAND
		ACALL LCD_DATA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		ACALL READ_KEY
		ACALL CLEAR_COMAND
		MOV R3,A 
		ACALL LCD_DATA
		SJMP CONT_GET2
NO_2ND_DIG:
		MOV A,R2
		ACALL CLEAR_COMAND
		ACALL LCD_DATA
		MOV R3,A 
		MOV A,R1
		MOV R2,A 
		MOV R1,#30H
CONT_GET2:
SK_NUM:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ACALL READ_KEY
	ACALL CLEAR_COMAND
	MOV R4,A 
	ACALL LCD_DATA
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ACALL READ_KEY
	ACALL CLEAR_COMAND
	MOV R5,A 
	ACALL LCD_DATA


	MOV A,ANS_CHECK
	CJNE A,#00H,SK_CHECK
	MOV A,R1
	LCALL EQ_ERROR
	CJNE R1,#30H,NUM1_1ST_DIG_CHECK
NUM1_1ST_DIG_CHECK:
	JNC CONT_CHECK1
	MOV R0,#ERROR
	LJMP RESULT

CONT_CHECK1:
	MOV A,R2
	LCALL EQ_ERROR
	CJNE R2,#30H,NUM1_2ND_DIG_CHECK
NUM1_2ND_DIG_CHECK:
	JNC CONT_CHECK2
	MOV R0,#ERROR
	LJMP RESULT
CONT_CHECK2:
	MOV A,R3
	LCALL EQ_ERROR
	CJNE R3,#30H,OPR_CHECK
OPR_CHECK:
	JC CONT_CHECK3
	MOV R0,#ERROR
	LJMP RESULT
SK_CHECK:
CONT_CHECK3:
	MOV A,R4
	LCALL EQ_ERROR
	CJNE R4,#30H,NUM2_1ST_DIG_CHECK
NUM2_1ST_DIG_CHECK:
	JNC CONT_CHECK4
	MOV R0,#ERROR
	LJMP RESULT
CONT_CHECK4:
	MOV A,R5
	LCALL EQ_ERROR
	CJNE R5,#30H,NUM2_2ND_DIG_CHECK
	NUM2_2ND_DIG_CHECK:
	JNC NO_ERORR
	MOV R0,#ERROR
	LJMP RESULT
NO_ERORR:
	CJNE R3,#'+',SUB_CHECK
	MOV R0,#0
	LCALL DIG2NUM
	MOV A,R1
	ADD A,R5
	LCALL OUTPUT
	SJMP RESULT
SUB_CHECK:
	CJNE R3,#'-',MUL_CHECK
	MOV R0,#0	; AS A FLAG FOR NO ERROR 
	LCALL DIG2NUM
	MOV A,R1
	SUBB A,R5
	JNC SUB_POS
	MOV R0,#NEG
	CPL A 
	ADD A,#1
SUB_POS:
	LCALL OUTPUT
	SJMP RESULT
MUL_CHECK:
	CJNE R3,#'*',DIV_CHECK
	MOV R0,#0      ;AS A FLAG FOR NO ERROR 
	LCALL DIG2NUM
	MOV B,R1
	MOV A,R5
	MUL AB 
	MOV R7,A
	MOV A,B
	CJNE A,#00H,OVFLOW
	MOV A,R7
	LCALL OUTPUT
	SJMP RESULT  
OVFLOW:
	MOV R0,#OVERFLOW
DIV_CHECK:
	CJNE R3,#'/',RESULT
	LCALL DIG2NUM 
	CJNE R5,#0,VALID_DIV
	MOV R0,#ERROR
	SJMP RESULT
VALID_DIV:
	MOV A,R1
	MOV B,R5
	MOV TEMP_2ND_OP,R5 
	DIV AB
	MOV TEMP_REM,B 
	LCALL OUTPUT 
RESULT:
	ACALL READ_KEY
	ACALL CLEAR_COMAND
	CJNE A,#'=',END_CALC
	ACALL LCD_DATA
	LCALL DELAY 
	
	CJNE R0,#ERROR,CONT_CALC
	MOV DPTR, #600H
AGA:
	MOV A,#0
	MOVC A,@ A+DPTR 
	JZ END_CALC 
	LCALL LCD_DATA
	ACALL DELAY 
	INC DPTR
	SJMP AGA 
CONT_CALC:

	CJNE R0,#NEG,CONT_CALC1
	MOV R7,A 
	MOV A,#'-'
	LCALL LCD_DATA
	LCALL DELAY 
	MOV A, R7 
	CONT_CALC1:
	CJNE R0,#OVERFLOW,CONT_CALC2
	MOV DPTR, #650H
AGA1:
	MOV A,#0
	MOVC A,@ A+DPTR 
	JZ END_CALC  
	LCALL LCD_DATA
	ACALL DELAY 
	INC DPTR
	SJMP AGA1 
CONT_CALC2:
		MOV A,R4
		MOV 22H,R4
		JZ SK_1STDIG_OUT
		ORL A,#30H
		LCALL LCD_DATA
		LCALL DELAY
SK_1STDIG_OUT:
		MOV A,R2
		JNZ SK2
		MOV A,22H
		JZ SK3
SK2:
		MOV A,R2
		ORL A,#30H
		LCALL LCD_DATA
		LCALL DELAY
SK3:
		MOV A,R1
		ORL A,#30H
		LCALL LCD_DATA
		LCALL DELAY
		CJNE R3,#'/',END_CALC
		MOV A,#'.'
		LCALL LCD_DATA
		LCALL DELAY
		LCALL FRAC
END_CALC:
		LCALL READ_KEY
		MOV TEMP,A
		LCALL LCD_CLEAR
		MOV A,TEMP

		CJNE A,#30H,DIG_OR_OPR
DIG_OR_OPR:
		JNC IN_DIGIT
		MOV ANS_CHECK,#15H
		MOV DPTR, #700H
		AGA_ANS:
		MOV A,#0
		MOVC A,@ A+DPTR 
		JZ ANS_END  
		LCALL LCD_DATA
		ACALL DELAY 
		INC DPTR
		SJMP AGA_ANS  
ANS_END:
		MOV A,TEMP
		MOV R3,A
		LCALL LCD_DATA
		LCALL DELAY

		MOV A,ANS_VALUE
		MOV R1,A 
LJMP SK_NUM

IN_DIGIT:
	MOV R0,A
	MOV ANS_CHECK,#00H
LJMP MAIN



CLEAR_COMAND:
		CJNE A,#'c',CONT1
		MOV R0,#00H
		MOV ANS_CHECK,#00H
		ACALL LCD_CLEAR
		LJMP MAIN

		CONT1:
RET

OUTPUT:
		MOV ANS_VALUE,A 
		MOV R7 ,A
		MOV R6, #3
		LOOP: MOV B,#10
		MOV A, R7
		DIV AB 
		MOV R7, A 
		MOV A, B  
		PUSH ACC
		DJNZ R6,LOOP 

		POP 4
		POP 2
		POP 1
RET

DIG2DES:
		MOV A,ANS_CHECK
CJNE A,#00H,SK_1ST_2DIG
		MOV A,R1 
		ANL A,#0FH
		MOV R1,A 

		MOV A,R2 
		ANL A,#0FH
		MOV R2,A 
		;;;;;;;;;;;;;;;;;
SK_1ST_2DIG:
		MOV A,R4
		ANL A,#0FH
		MOV R4,A 

		MOV A,R5 
		ANL A,#0FH
		MOV R5,A 
RET
DIG2NUM:
		ACALL DIG2DES

		MOV A,ANS_CHECK
CJNE A,#00H,SK_1ST_NUM
		MOV B,#10
		MOV A,R1
		MUL AB
		ADD A,R2
		MOV R1,A

SK_1ST_NUM:
		MOV B,#10
		MOV A,R4
		MUL AB
		ADD A,R5
		MOV R5,A
RET

EQ_ERROR:
		CJNE A,#'=',NOT_EQ 
		MOV R0,#ERROR
		LJMP RESULT
NOT_EQ:
RET

FRAC:
		MOV R7,#3
		LOOP_NG:
		MOV A,TEMP_REM
		MOV B,#10
		MUL AB
		MOV B,TEMP_2ND_OP
		DIV AB
		MOV TEMP_REM,B 
		MOV B ,#0AH
		DIV AB 
		MOV A,B 
		CJNE R7,#1,SK_TEST
		JZ END_LOOP_NG
		SK_TEST:
		ADD A,#30H
		LCALL LCD_DATA
		LCALL DELAY
		END_LOOP_NG:
		DJNZ R7,LOOP_NG 
RET 


READ_KEY:
		K1: CLR RO1            ;Ground all columns at first
		CLR RO2 
		CLR RO3
		CLR RO4

		MOV A, KEYPAD                   ; Read keypad inputs
		ANL A, #0FH                    ;mask left 4 bits, check only right left bits
		CJNE A,#00001111B,K2         ;if any zero at any column so there is a press
			
		;if A equal 0000 1111 so no press, REPEAT AGAIN 
		Sjmp K1
		;if it is a press,make sure this press is real,, debouncing 
		K2: ACALL Delay
		;repeat check again
		MOV A, KEYPAD              ;Read keypad inputs
		ANL A, #0FH
		CJNE A, #00001111B, check_row            ;if any zero at least 4 bits, a key is pressed
		;go to check which row ?
		;not a real press, go again 
		SJMP K1

		check_row: 
		CLR RO1            ;check first row
		SETB RO2
		SETB RO3
		SETB RO4

		MOV A, KEYPAD               ;READ VALUE ON PORT
		CJNE A,#01111111B, ROW_1      ;if there is a zero on any of the column, there is a press in rowl
		;if not scan second row
		SETB RO1           ; check second row
		CLR RO2
		SETB RO3
		SETB RO4
		MOV A, KEYPAD         ;READ VALUE ON PORT
		CJNE A, #10111111B, ROW_2             ;if there is a zero on any of the column, there is a press in rowl 
		;if not scan third row
		SETB RO1            ; check third row
		SETB RO2
		CLR RO3
		SETB RO4

		MOV A, KEYPAD            ;READ VALUE ON PORT
		CJNE A, #11011111B, ROW_3        ;if there is a zero on any of the column ,there is a press in rowl
		;if not scan fourth row
		SETB RO1
		SETB RO2          ; check fourth row
		SETB RO3
		CLR RO4
		MOV A, KEYPAD              ;READ VALUE ON PORT
		CJNE A,#11101111B, ROW_4          ;if there is a zero on any of the column, there is a press in rowl
		;if not repeat again
		LJMP K1

		ROW_1: MOV DPTR,#ROW1            ;access memory at this row but which column
				SJMP FIND
		ROW_2: MOV DPTR,#ROW2 
				SJMP FIND
		ROW_3: MOV DPTR,#ROW3 
				SJMP FIND
		ROW_4: MOV DPTR,#ROW4 
				SJMP FIND
				
		FIND: MOV R7,#4             ; check which bit is zero
		AGAIN: RRC A
		JNC MATCH                 ;if lsb is zero so it is in first column
		INC DPTR                  ;if not increment next location
		SJMP AGAIN

		MATCH: CLR A
		MOVC A,@ A+DPTR             ; key read now in accumlator
		RET

		DELAY: MOV R5, #255
		LL:MOV R6, #255
		LL2:DJNZ R6, LL2
		DJNZ R5,LL
RET

LCD_INIT: 
		MOV A, #38h
		ACALL LCD_COMM 
		ACALL DELAY 
		MOV A, #0EH
		ACALL LCD_COMM 
		ACALL DELAY

		MOV A, #01
		ACALL LCD_COMM
		ACALL DELAY 
RET

LCD_CLEAR:
		MOV A, #01
		ACALL LCD_COMM
		ACALL DELAY
RET  
;clear the screen
LCD_COMM: 
		MOV LCD_PORT, A       ;write command to D0-D7
		CLR RS
		SETB E                    ;RS=0 for sending commands give a pulse of enable to LCD
		NOP
		NOP
		NOP
		CLR E
RET

LCD_DATA:
		MOV LCD_PORT, A
		SETB RS
		SETB E
		NOP
		NOP
		NOP
		NOP
		CLR E
RET                      ;Delay subroutine


ORG 500H
	ROW1:DB '7', '8', '9','/' 
	ROW2:DB '4', '5', '6','*' 
	ROW3:DB '1', '2', '3','-'
	ROW4:DB 'c', '0', '=','+'

ORG 600H
	MES1:DB 'ERROR',0

ORG 650H
	MES2:DB 'TOO MUCH',0

ORG 700H
	MES3:DB 'ANS',0 
end