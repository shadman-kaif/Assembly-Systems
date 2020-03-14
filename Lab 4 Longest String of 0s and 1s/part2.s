/* Program that counts multiple words for consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
					MOV     R3, #TEST_NUM   // load the data word ...
					MOV     R5, #0          // holds greatest count of strings, R5 will have result

MAIN:               LDR     R1,[R3],#4	// get next word     
		    CMP     R1,#0	// done whole list?
		    BEQ     END
		    BL      COUNT_ONES  // link register to subroutine
		    CMP     R5,R0       
		    MOVLT   R5,R0	// keep best result in R5
		    B  	    MAIN
		  
COUNT_ONES:         MOV     R0, #0          // R0 will hold the result
LOOP:               CMP     R1, #0          // loop until the data contains no more 1's
		    BEQ     COUNT_ONES_END             
		    LSR     R2, R1, #1      // perform SHIFT, followed by AND
		    AND     R1, R1, R2      
		    ADD     R0, #1          // count the string length so far
		    B       LOOP       
					
COUNT_ONES_END:     MOV     PC,LR

END:      B       END             

N: .word 10 
TEST_NUM: .word   0x00000001  
          .word   0x00000002
	  .word   0x00000007
	  .word   0x0000000f
          .word   0x0000001f
          .word   0x0000002f
          .word   0x0000007f
          .word   0x100000ff
          .word   0x100001ff
          .word   0xfffff2ff
	  .word   0xffffffff
 	  .word   0x00000000
          .end   