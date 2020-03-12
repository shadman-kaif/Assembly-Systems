/*LAB5PART2*/

	.text
	.global _start

_start:   LDR     R4, =0xFF200000           // Base Address for LEDR
          MOV     R3, #0                    // Counter Register (holds the value being incremented) 

DISPLAY:  LDR     R1, [R4, #0x5C]           // Get the Edge Capture register value
		  CMP     R1, #0            // Check if a key is pressed, according to the edge capture register value
		  BEQ     NOKEYPRESS    

WAIT:     MOV     R1, #0b1111               // Only if a key is pressed, assert 1 into edge capture register to reset
          STR     R1, [R4, #0x5C]           
          LDR     R1, [R4, #0x5C]           // Get updated Edge Capture register value
          B       UNPAUSE                  

UNPAUSE:  LDR     R1, [R4, #0x5C]          //Is button pressed? Can continue to increment, if pressed.
          CMP     R1, #0            
          BEQ     UNPAUSE

NOKEYPRESS:   MOV     R1, #0b1111         // Reset the Edge Capture register value to press button again later
              STR     R1, [R4, #0x5C]
              LDR     R1, [R4, #0x5C]
              CMP     R3, #99
              BEQ     _start              // Loop back to 0 after 99

              LDR     R8, =0xFF200020    // Display Decimal digits on HEX1-0
              MOV     R0, R3          
              BL      DIVIDE          
                                  
              MOV     R9, R1          
              BL      SEG7_CODE
              MOV     R5, R0          
              MOV     R0, R9         
                                      
              BL      SEG7_CODE
              LSL     R0, #8
              ORR     R5, R0

              STR     R5, [R8]

              LDR     R2, =500000

DELAY:        SUBS     R2, #1
              BNE     DELAY
              ADD     R3, #1
              B       DISPLAY

DIVIDE:       MOV    R2, #0    // Divide to get tens digit and ones digit separate
CONT:         CMP    R0, #10
              BLT    DIV_END
              SUB    R0, #10
              ADD    R2, #1
              B      CONT
DIV_END:      MOV    R1, R2     // R1 has quotient 
              MOV    PC, LR


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
