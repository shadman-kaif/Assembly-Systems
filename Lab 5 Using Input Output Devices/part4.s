          .text                   // executable code follows
          .global _start                  
_start:
	mov		r3, #0		//r3 will be the counter //This counts 100ths 
	mov		r4, #0		//this is seconds counter
	mov		r0, #0		//THIS IS THE PRESSED FLAG
	mov		r9, #1; //E bit is 1
	ldr		r8, =0xFFFEC600
	LDR 	R7, =2000000 // delay counter counts by 0.01 seconds
LOOP:	
	ldr		r12, =0xFF20005C
	ldr		r12, [r12]	//edge capture for keys
	cmp		r12, #0
	blne	HANDLE_EDGE	//something is a one
	cmp		r0, #1
	beq		LOOP		//something was pressed //stop displaying (i.e pause)
	bl		DISPLAY		//display r3				
DO_DELAY:
	str		r7, [r8]
	str		r9, [r8, #8] //0xFFFEC608 //turn it on
SUB_LOOP:
	ldr		r10, [r8, #0xc]
	cmp		r10, #1
	BNE 	SUB_LOOP
	str		r10, [r8, #0xc] //reset the edge capture
	add		r3,r3, #1	//hit 0
	cmp		r3, #100
	beq		RESET
	b		LOOP

RESET:	mov	r3, #0
	add r4, r4, #1
	cmp	r4, #60	//loop around
	beq	RESET_SS
	b	LOOP
	
RESET_SS:
	mov r4, #0
	b LOOP

HANDLE_EDGE:
	ldr	r2, =0xFF20005C
	mov	r1, r12		//write 1 to exactr position
	str	r1, [r2]	//reset the edge trigger
	eor	r0, #1		//invert
	mov	pc, lr
	

SEG7_CODE:  MOV     R1, #BIT_CODES
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]	   // load the bit pattern (to be returned)
            MOV     PC, LR

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2	   // pad with 2 bytes to maintain word alignment

DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B	   CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

/* R4 on display 3 and 2, R3 holds input number in binary*/
DISPLAY:PUSH    {r4, r8, r10, r9, r0, r1,r2, r5, LR}
	LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R3          // display R3 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R5, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R5, R0
           
            MOV     R0, R4          // display R4 on HEX3-2
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R10, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #24
            LSL		R10,#16
            ORR     R0, R10
            ORR	    r5, R0
            STR     r5, [R8]        // display the numbers from R4 and R3
	POP	{r4, r8, r9, r10, r0, r1, r2, r5, LR}
	MOV	PC, LR
	

