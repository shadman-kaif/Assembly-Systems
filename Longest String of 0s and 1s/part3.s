
		  .text                   // executable code follows
          .global _start   

		  _start:                             
          MOV     R8, #TEST_NUM   
		  MOV	  R5, #0
		  MOV     R6, #0
		  MOV     R7, #0

MAIN:     LDR     R1, [R8]     		// R1 receives input data    
		  CMP	  R1, #0 	// Checks for the 0 word to terminate the program
		  BEQ     END
		  BL	  ONES          // Link register to ONES subroutine
		  CMP	  R5, R0
		  MOVLT   R5, R0	// Keep best result in R5

		  LDR     R1, [R8]         
		  MOV     R2, #ALL_F
		  LDR     R2, [R2]
		  BL	  ZEROS		// Going to ZEROS subroutine
		  CMP	  R6, R0
		  MOVLT   R6, R0	// Keep best result in R6

		  LDR     R1, [R8]         
		  MOV     R3, #ALT
		  LDR     R3, [R3]
		  BL	  ALTERNATE	// Alternate subroutine
		  CMP	  R7, R0
		  MOVLT   R7, R0	// keep best result in R7

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