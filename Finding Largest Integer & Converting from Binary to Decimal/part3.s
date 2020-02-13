/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           // Go to Large, store PC value in LR
            MOV	    R4, R0          // R0 holds the largest value in the list after the return from subroutine

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the list
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list
 */

LARGE:      MOV R3, R0 		// R3 points to number of elements in the list, allowing R0 to hold the largest number
	    LDR R0, [R1] 	// R0 holds first number in list
			
LOOP: 		
	    SUBS 	R3, #1  	// Decrement R3 by 1 
	    MOVEQ 	PC, LR		// Checks if the loop is done, returns to main if it is done
	    LDR		R2, [R1], #4 	// Load R2 with next value in array
	    CMP		R0, R2		// Compare R0 with R2
	    BGE		LOOP		// If R0 - R2 is greater than equal to 0, start at LOOP again	
	    MOV		R0, R2		// if R2 > R0, R0 points to R2
	    B		LOOP		// Loop again

RESULT:     .word   0           
N:          .word   7              // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6     // the data
            .word   1, 8, 2                 

            .end     