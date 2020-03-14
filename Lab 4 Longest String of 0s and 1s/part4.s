 .text                   // executable code follows
          .global _start   

		  _start:                             
          MOV     R8, #TEST_NUM   
		  MOV	  R5, #0
		  MOV     R6, #0
		  MOV     R7, #0

MAIN:     LDR     R1, [R8]        
		  CMP	  R1, #0
		  BEQ     DISPLAY
		  BL	  ONES
		  CMP	  R5, R0
		  MOVLT   R5, R0

		  LDR     R1, [R8]         
		  MOV     R2, #ALL_F
		  LDR     R2, [R2]
		  BL	  ZEROS
		  CMP	  R6, R0
		  MOVLT   R6, R0

		  LDR     R1, [R8]         
		  MOV     R3, #ALT
		  LDR     R3, [R3]
		  BL	  ALTERNATE
		  CMP	  R7, R0
		  MOVLT   R7, R0

		  ADD	  R8, #4
		  B		  MAIN

ONES:     MOV     R0, #0          // R0 will hold the result
ONES_LOOP:CMP     R1, #0          // loop until the data contains no more 1's
          MOVEQ   PC, LR            
          LSR     R3, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R3      
          ADD     R0, #1          // count the string length so far
          B       ONES_LOOP  


ZEROS:    MOV     R0, #0          // R0 will hold the result
	      EOR     R1, R2          // Invert the bits
ZEROS_LOOP: CMP     R1, #0          // loop until the data contains no more 1's
          MOVEQ   PC, LR            
          LSR     R3, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R3      
          ADD     R0, #1          // count the string length so far
          B       ZEROS_LOOP  



ALTERNATE:  MOV     R0, #0          // R0 will hold the result
			EOR     R1, R3          // XOR with alternating
ALT_LOOP: CMP     R1, #0          // loop until the data contains no more 1's
          MOVEQ   PC, LR            
          LSR     R3, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R3      
          ADD     R0, #1          // count the string length so far
          B       ALT_LOOP 

		  
END:      B       END   



/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

DIVIDE:		MOV		R2, #0
CONT:		CMP		R0, #10
			BLT		DIV_END
			SUB     R0, #10
			ADD     R2, #1
			B       CONT
DIV_END:    MOV     R1, R2
            MOV     PC, LR

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
            MOV     R0, R6          // display R6 on HEX3-2
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            LSL     R0, #16         // save bit code
			ORR     R4, R0
            MOV     R0, R9          // retrieve the tens digit, get bit code
            BL      SEG7_CODE  
			LSL     R0, #24
            ORR     R4, R0
            STR     R4, [R8]        // display the numbers from R6 and R5
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            MOV     R0, R7          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
            STR     R4, [R8]        // display the number from R7
			B		END


ALL_F:    .word 0xffffffff
ALT:      .word 0x55555555
TEST_NUM: .word   0x103fe00f // 9 9 2
		  .word   0x103f000f // 6 12 2
		  .word   0x100000ff // 8 20 2
		  .word   0x0800f000 // 4 12 3
		  .word   0x1000ffff // 16 12 2
		  .word	  0x3ffe0001 //13 16 2
		  .word   0x11111111 // 1 3 1?
		  .word   0xffff00aa // 16 8 9?
		  .word   0x0f0f002a // 4 10 7?
		  .word   0xfffff000 // 20 12 1?
		  .word   0x00000000

          .end     