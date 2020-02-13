/* Program that converts a binary number to decimal */
.text // executable code follows
.global _start

_start:
			MOV    R4, #N
			MOV    R5, #Digits     // R5 points to the decimal digits storage location
			LDR    R4, [R4]        // R4 holds N
			MOV    R0, R4          // parameter for DIVIDE goes in R0
			
			MOV    R1, #1000       // 1000 used for division for 4 digits
			
			BL     DIVIDE          // Divide using parameter
			
			STRB   R1, [R5, #3]    // Stores quotient in first place holder
			MOV    R1, #100        // Changes parameter to 100
			BL     DIVIDE          // Divides using new parameter
			STRB   R1, [R5,#2]     // Stores quotient into the second placeholder
			MOV    R1, #10         // Changes parameter to 10
			BL     DIVIDE          // Divides using new parameter

			STRB   R1, [R5, #1]    // Tens digit is now in R1
			STRB   R0, [R5]        // Ones digit is in R0

END: B END

/* Subroutine to perform the integer division R0 / 10.
* Returns: quotient in R1, and remainder in R0
*/

DIVIDE:     MOV    R2, #0

CONT:   	CMP    R0, R1          // Compares R0 and R1
			BLT    DIV_END         // If result is less than 0, DIV_END
			SUB    R0, R1          // Subtract R1 from R0
			ADD    R2, #1          // Adds 1 to R2 to see how many R1's can fit in R0
			B      CONT            // Repeat CONT until R0 is less than R1


DIV_END:    MOV    R1, R2          // quotient in R1 (remainder in R0)
			MOV    PC, LR
			
N: 			.word  76              // the decimal number to be converted

Digits:     .space 4               // storage space for the decimal digits
			.end