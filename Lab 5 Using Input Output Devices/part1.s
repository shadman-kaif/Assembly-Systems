/*LAB5PART1*/


	.text
	.global _start

_start:     LDR R0, =0xFF200000 // Base Address for LEDS
	    MOV R1, #BIT_CODES   // Address of BIT_CODES
	    
            MOV R8, #0           // For blank case
            MOV R3, #0           // For storing pressed key
            MOV R6, #0           // counter

DISPLAY:    

PAUSE:	    LDR R5, [R0, #0x50]  // read from the KEYs
	    CMP R5, #0 // if not 0 then a button is pushed                         
            BEQ PAUSE // wait till key is pressed
            
KEY_PRESSED: MOV R3, R5            
    
WAIT: 	    LDR R5, [R0, #0x50] // read KEYs
	    CMP R5, #0          // check if KEY is released
            BNE WAIT
            
	    ANDS R2, R3, #0b00000001 // KEY0 pressed
            BGT SHOW_ZERO
            
            ANDS R2, R3, #0b00000010 // KEY1 pressed
            BGT SHOW_INCR
            
            ANDS R2, R3, #0b00000100 // KEY2 pressed
            BGT SHOW_DECR
         
            ANDS R2, R3, #0b00001000 // KEY3 pressed
            BGT SHOW_NOTHING

SHOW_ZERO:  MOV R6, #0
            MOV R1, #BIT_CODES
            LDRB R3, [R1]       // load 0 into the hex
            STR R3, [R0, #0x20] // store the bit code into HEX0
	    B DISPLAY      

SHOW_INCR:  ADD R1, #1         // to determine which bitcode
	    ADD R6, #1         // counter
	    CMP R6, #10        // check if loop back to 0 is needed
	    BGT LOOP_GTNINE
            CMP R4, #0         // counter to determine if HEX was reset with KEY3
            SUBEQ R1, #1       // R1 should not have been incremented 
            ADD R4, #1            
            LDRB R3, [R1]
            STR R3, [R0, #0x20] // store the bit code into HEX0
	    B DISPLAY  

LOOP_GTNINE:  MOV R1, #BIT_CODES   // in case of loop back reset bitcode
	      LDRB R3, [R1]
	      ADD R4, #1           // KEY3 was not pressed so increment
	      MOV R6, #0           // reset base counter
	      STR R3, [R0, #0X20]  // store the bit code into HEX0
	      B DISPLAY          

SHOW_DECR:  
            
            SUB R1, #1           // Determine which bitcode
	    SUB R6, #1           // counter
	    CMP R6, #0           // check if need for loop back to 9
	    BLT LOOP_LTZERO
            CMP R4, #0           // check if KEY3 was pressed
            ADDEQ R1, #1	 // if KEY3 was pressed no need to decrement R1
	    ADD R4, #1
            LDRB R3, [R1]
            STR R3, [R0, #0x20] // store the bit code into HEX0
	    B DISPLAY

LOOP_LTZERO:  MOV R1, #BIT_CODES  // reset bitcode
	    ADD R1, #9
	    LDRB R3, [R1]
	    ADD R4, #1 		
	    MOV R6, #10		  // adjust counter
	    STR R3, [R0, #0X20]   // store the bit code into HEX0
	    B DISPLAY             

SHOW_NOTHING: MOV R4, #0          // to determine KEY3 was pressed so any other KEY after will display 0
              MOV R1, #BIT_CODES  
              STR R8, [R0, #0x20] // store the bit code into HEX0
              B DISPLAY

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

