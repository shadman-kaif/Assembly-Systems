
		.section .vectors, "ax"  
                B        _start         // reset vector
                B  	 IRQ_HANDLER    // undefined instruction vector
                B	 IRQ_HANDLER    // software interrupt vector
                B	 IRQ_HANDLER    // aborted prefetch vector
                B	 IRQ_HANDLER    // aborted data vector
                .word    0              // unused vector
                B	 IRQ_HANDLER    // IRQ interrupt vector
                B	 IRQ_HANDLER    // FIQ interrupt vector

                .text
		.global	_start

_start:		
		/* Set up stack pointers for IRQ and SVC processor modes */
		MSR CPSR_c, #0b11010010 // Moved into IRQ mode, disabled interrupts as well
		LDR SP, =0x20000        // sets IRQ Banked Stack Pointer
                MSR CPSR, #0b11010011   // moved into SVC mode, disabled interrupts
                LDR SP, =0x40000        // set SVC Banked Stack Pointer
		
		BL CONFIG_GIC		// configure the ARM generic interrupt controller

		BL CONF_TIMER

/* Configure the KEY pushbuttons port to generate interrupts */

		LDR R0, =0xFF200050     // pushbutton KEY base address
		MOV R1, #0xF	        // set interrupt mask bit
		STR R1, [R0, #0x8]      // interrupt mask register is (base + 8)

/* Enable IRQ interrupts in the ARM processor */

		MOV R0, #0b01010011     // IRQ unmasked, MODE = SVC
		MSR CPSR, R0
				
		LDR R5, =0xFF200000     // LEDR base address
		LDR R0, =0xFF202000
		MOV R1, #0
		STR R1, [R0]
				
LOOP:		LDR R0, =COUNT
		LDR R0, [R0]
		MOV R11, R0
			
		BL DISPLAY
		B LOOP


/* Global variables */ 

	.global COUNT
COUNT:  .word 0x0         // used by timer
        .global RUN // used by pushbutton KEYs
RUN:    .word 0x1 // initial value to increment


IRQ_HANDLER:
		PUSH {R0-R5, LR}    			
/* Read the ICCIAR from the CPU interface */
    		LDR R4, =0xFFFEC100
    		LDR R5, [R4, #0xC]	// read from ICCIAR

CHECK_KEYS: 	CMP R5, #73
		BEQ GO_KEY
    
CHECK_TIMER:    CMP R5, #72
		BEQ GO_TIMER
	
GO_TIMER:	BL TIMER_ISR	
		B EXIT_IRQ

GO_KEY:		BL KEY_ISR	// pass R0 as a parameter to KEY_ISR	
		B EXIT_IRQ

EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    		STR R5, [R4, #0x10]	// write to ICCEOIR    
    		POP {R0-R5, LR}
    		SUBS PC, LR, #4				

		.global	KEY_ISR				
								
KEY_ISR:	LDR R1, =0xff20005c
		LDR R1, [R1]
				
		//check the state of KEY0 by extracting the first bit				
		MOV R2, R1
		AND R2, #1
		CMP R1, #1
		BNE SLOW_DOWN
		LDR R0, =RUN				
		LDR R0, [R0]
		CMP R0, #1
		BNE CHANGE_TO_ONE
		MOV R1, #0
		LDR R0, =RUN				
		STR R1, [R0]
		B GO_BACK

SLOW_DOWN:		MOV R2, R1		//check key 1
		AND R2, #2
		CMP R1, #2
		BNE FASTER_RATE
		PUSH {R0-R5}
		LDR	R0, =0xFF202000
		
		//clear the interrupt
		MOV		R1, #0x1
		STR		R1, [R0]
				
		LDR	R1, [R0,#0x8]				
		LDR	R2, [R0,#0xC]	//needs to be left shifted 64 times			
				
		MOV	R3, #0b1000
		STR	R3, [R0,#0x4] //stop the timer				
				
		MOV	R3, #0b0011
		STR	R3, [R0, #0x4] //stop state				
								
		LSL R2, #16 				 
		ORR R2, R1
		//right shift to reduce the time
		LSR R2, #1
		MOV R3, R2
		//extract the high word
		LDR R5, =0xFFFF0000
		AND R2, R5 //r2 now has the high word to be stored in base + 0xc
		LSR R2, #16
		STR R2, [R0, #0xc]
		//extract the low word
		LDR R5, =0xFFFF
		AND R3, R5
		STR R3, [R0, #0x8] //store it				
		//start it (the timer)
		MOV		R1, #0b111
		STR		R1, [R0,#0x4]	
		POP {R0 -R5}
		B GO_BACK

FASTER_RATE:	MOV R2, R1		//check key 1
		AND R2, #4
		CMP R1, #4
		BNE GO_BACK
		PUSH {R0-R4}
		LDR	R0, =0xFF202000
				
		//clear the interrupt
		MOV		R1, #0x1
		STR		R1, [R0]
				
		LDR R1, [R0,#0x8]				
		LDR R2, [R0,#0xC]	//needs to be left shifted 64 times			
				
		MOV R3, #0b1000
		STR R3, [R0,#0x4] //stop the timer				
				
		MOV R3, #0b0011
		STR R3, [R0, #0x4] //stop state				
								
		LSL R2, #16 				 
		ORR R2, R1
		//left shift to increase the time
		LSL R2, #1
		MOV R3, R2
		//extract the high word
		LDR R4, =0xFFFF0000
		AND R2, R4 //r2 now has the high word to be stored in base + 0xc
		LSR R2, #16
		STR R2, [R0, #0xc]
		//extract the low word
		LDR R4, =0xFFFF
		AND R3, R4
		STR R3, [R0, #0x8] //store it				
		//start it (the timer)
		MOV R1, #0b111
		STR R1, [R0,#0x4]	
		POP {R0 - R4}	
		B GO_BACK

GO_BACK:	LDR R0, =0xFF20005C   // base address of pushbutton KEY port
		MOV R2, #0xF
		STR R2, [R0]				
		MOV PC, LR	      // return

CHANGE_TO_ONE:	MOV R1, #1
		LDR R0, =RUN
		STR R1, [R0]
		B GO_BACK

TIMER_ISR:    	PUSH {R0-R5}	    //acknowledge interrupt				
		LDR R1, =COUNT
		LDR R2, =RUN
		LDR R1, [R1]        //r1 has the count
		LDR R2,	[R2] 	    //r2 has the run
		ADD R1, R2	    // add r1 and r2
		LDR R0, =COUNT		
		STR R1, [R0]
		LDR R0, =0xFF202000  // base address of interval timer port
		MOV R1, #0x1
		STR R1, [R0]         // clear the interrupt				
		POP {R0-R5}
		MOV PC, LR


CONF_TIMER: 	PUSH {R0, R1}
		LDR R0, =0xFF202000
		LDR R1, =0x7840
		STR R1, [R0,#0x8]
		LDR R1, =0x017D
		STR R1, [R0,#0xC]
		MOV R1, #0b111
		STR R1, [R0,#0x4]										
		POP {R0, R1}				
		MOV PC, LR

SEG: 	   	PUSH {R1}
			LDR     R1, =BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
			POP {R1}			
            MOV     PC, LR              

.global BIT_CODES
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment				

DISPLAY:    PUSH {R0, R1, R9, R8, R7} //push for sanity
			LDR R12, =0xFF200020 // base address of HEX3-HEX0			
			MOV R7, R0 //temporarily store R0
			PUSH {LR}
			BL DIVIDE  //divide the number
			MOV R9, R0 //save the remainder in R9
			MOV R0, R1 //move the quotient to r0
			
			BL SEG	   //get bit code for the quotient		
 			LSL R0, #8 //left shift the register
			MOV R8, R0 //store the reg in r8
			MOV R0, R9 //bring back the remainder			
			BL SEG     //get its bit code
			ORR R0, R8, R0 //add
			
			STR R0, [R12]
			POP {LR}
			POP {R0, R1, R9, R8, R7} //pop for sanity
			MOV PC, LR

DIVIDE:    PUSH {R2}
			MOV    R2, #0
CONTD:      CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONTD
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
			POP {R2}
            MOV    PC, LR

            		

/* FPGA interrupts (there are 64 in total; only a few are defined below) */
			.equ	INTERVAL_TIMER_IRQ, 			72
			.equ	KEYS_IRQ, 						73
			.equ	FPGA_IRQ2, 						74
			.equ	FPGA_IRQ3, 						75
			.equ	FPGA_IRQ4, 						76
			.equ	FPGA_IRQ5, 						77
			.equ	AUDIO_IRQ, 						78
			.equ	PS2_IRQ, 						79
			.equ	JTAG_IRQ, 						80
			.equ	IrDA_IRQ, 						81
			.equ	FPGA_IRQ10,						82
			.equ	JP1_IRQ,							83
			.equ	JP2_IRQ,							84
			.equ	FPGA_IRQ13,						85
			.equ	FPGA_IRQ14,						86
			.equ	FPGA_IRQ15,						87
			.equ	FPGA_IRQ16,						88
			.equ	PS2_DUAL_IRQ,					89
			.equ	FPGA_IRQ18,						90
			.equ	FPGA_IRQ19,						91

/* ARM A9 MPCORE devices (there are many; only a few are defined below) */
			.equ	MPCORE_GLOBAL_TIMER_IRQ,	27
			.equ	MPCORE_PRIV_TIMER_IRQ,		29
			.equ	MPCORE_WATCHDOG_IRQ,			30

/* HPS devices (there are many; only a few are defined below) */
			.equ	HPS_UART0_IRQ,   				194
			.equ	HPS_UART1_IRQ,   				195
			.equ	HPS_GPIO0_IRQ,          	196
			.equ	HPS_GPIO1_IRQ,          	197
			.equ	HPS_GPIO2_IRQ,          	198
			.equ	HPS_TIMER0_IRQ,         	199
			.equ	HPS_TIMER1_IRQ,         	200
			.equ	HPS_TIMER2_IRQ,         	201
			.equ	HPS_TIMER3_IRQ,         	202
			.equ	HPS_WATCHDOG0_IRQ,     		203
			.equ	HPS_WATCHDOG1_IRQ,     		204


/* Memory */
        .equ  DDR_BASE,	            0x00000000
        .equ  DDR_END,              0x3FFFFFFF
        .equ  A9_ONCHIP_BASE,	      0xFFFF0000
        .equ  A9_ONCHIP_END,        0xFFFFFFFF
        .equ  SDRAM_BASE,    	      0xC0000000
        .equ  SDRAM_END,            0xC3FFFFFF
        .equ  FPGA_ONCHIP_BASE,	   0xC8000000
        .equ  FPGA_ONCHIP_END,      0xC803FFFF
        .equ  FPGA_CHAR_BASE,   	   0xC9000000
        .equ  FPGA_CHAR_END,        0xC9001FFF

/* Cyclone V FPGA devices */
        .equ  LEDR_BASE,             0xFF200000
        .equ  HEX3_HEX0_BASE,        0xFF200020
        .equ  HEX5_HEX4_BASE,        0xFF200030
        .equ  SW_BASE,               0xFF200040
        .equ  KEY_BASE,              0xFF200050
        .equ  JP1_BASE,              0xFF200060
        .equ  JP2_BASE,              0xFF200070
        .equ  PS2_BASE,              0xFF200100
        .equ  PS2_DUAL_BASE,         0xFF200108
        .equ  JTAG_UART_BASE,        0xFF201000
        .equ  JTAG_UART_2_BASE,      0xFF201008
        .equ  IrDA_BASE,             0xFF201020
        .equ  TIMER_BASE,            0xFF202000
        .equ  AV_CONFIG_BASE,        0xFF203000
        .equ  PIXEL_BUF_CTRL_BASE,   0xFF203020
        .equ  CHAR_BUF_CTRL_BASE,    0xFF203030
        .equ  AUDIO_BASE,            0xFF203040
        .equ  VIDEO_IN_BASE,         0xFF203060
        .equ  ADC_BASE,              0xFF204000

/* Cyclone V HPS devices */
        .equ   HPS_GPIO1_BASE,       0xFF709000
        .equ   HPS_TIMER0_BASE,      0xFFC08000
        .equ   HPS_TIMER1_BASE,      0xFFC09000
        .equ   HPS_TIMER2_BASE,      0xFFD00000
        .equ   HPS_TIMER3_BASE,      0xFFD01000
        .equ   FPGA_BRIDGE,          0xFFD0501C

/* ARM A9 MPCORE devices */
        .equ   PERIPH_BASE,          0xFFFEC000   /* base address of peripheral devices */
        .equ   MPCORE_PRIV_TIMER,    0xFFFEC600   /* PERIPH_BASE + 0x0600 */

        /* Interrupt controller (GIC) CPU interface(s) */
        .equ   MPCORE_GIC_CPUIF,     0xFFFEC100   /* PERIPH_BASE + 0x100 */
        .equ   ICCICR,               0x00         /* CPU interface control register */
        .equ   ICCPMR,               0x04         /* interrupt priority mask register */
        .equ   ICCIAR,               0x0C         /* interrupt acknowledge register */
        .equ   ICCEOIR,              0x10         /* end of interrupt register */
        /* Interrupt controller (GIC) distributor interface(s) */
        .equ   MPCORE_GIC_DIST,      0xFFFED000   /* PERIPH_BASE + 0x1000 */
        .equ   ICDDCR,               0x00         /* distributor control register */
        .equ   ICDISER,              0x100        /* interrupt set-enable registers */
        .equ   ICDICER,              0x180        /* interrupt clear-enable registers */
        .equ   ICDIPTR,              0x800        /* interrupt processor targets registers */
        .equ   ICDICFR,              0xC00        /* interrupt configuration registers */

			.equ		EDGE_TRIGGERED,         0x1
			.equ		LEVEL_SENSITIVE,        0x0
			.equ		CPU0,         				0x01	// bit-mask; bit 0 represents cpu0
			.equ		ENABLE, 						0x1

			.equ		KEY0, 						0b0001
			.equ		KEY1, 						0b0010
			.equ		KEY2,							0b0100
			.equ		KEY3,							0b1000

			.equ		RIGHT,						1
			.equ		LEFT,							2

			.equ		USER_MODE,					0b10000
			.equ		FIQ_MODE,					0b10001
			.equ		IRQ_MODE,					0b10010
			.equ		SVC_MODE,					0b10011
			.equ		ABORT_MODE,					0b10111
			.equ		UNDEF_MODE,					0b11011
			.equ		SYS_MODE,					0b11111

			.equ		INT_ENABLE,					0b01000000
			.equ		INT_DISABLE,				0b11000000


/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
				.global	CONFIG_GIC
CONFIG_GIC:
				PUSH		{LR}
    			/* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #MPCORE_PRIV_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #INTERVAL_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #KEYS_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT

				/* configure the GIC CPU interface */
    			LDR		R0, =0xFFFEC100		// base address of CPU interface
    			/* Set Interrupt Priority Mask Register (ICCPMR) */
    			LDR		R1, =0xFFFF 			// enable interrupts of all priorities levels
    			STR		R1, [R0, #0x04]
    			/* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
				 * allows interrupts to be forwarded to the CPU(s) */
    			MOV		R1, #1
    			STR		R1, [R0]
    
    			/* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
				 * allows the distributor to forward interrupts to the CPU interface(s) */
    			LDR		R0, =0xFFFED000
    			STR		R1, [R0]    
    
    			POP     	{PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
    			PUSH		{R4-R5, LR}
    
    			/* Configure Interrupt Set-Enable Registers (ICDISERn). 
				 * reg_offset = (integer_div(N / 32) * 4
				 * value = 1 << (N mod 32) */
    			LSR		R4, R0, #3							// calculate reg_offset
    			BIC		R4, R4, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED100
				ADD		R4, R2, R4							// R4 = address of ICDISER
    
    			AND		R2, R0, #0x1F   					// N mod 32
				MOV		R5, #1								// enable
    			LSL		R2, R5, R2							// R2 = value

				/* now that we have the register address (R4) and value (R2), we need to set the
				 * correct bit in the GIC register */
    			LDR		R3, [R4]								// read current register value
    			ORR		R3, R3, R2							// set the enable bit
    			STR		R3, [R4]								// store the new register value

    			/* Configure Interrupt Processor Targets Register (ICDIPTRn)
     			 * reg_offset = integer_div(N / 4) * 4
     			 * index = N mod 4 */
    			BIC		R4, R0, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED800
				ADD		R4, R2, R4							// R4 = word address of ICDIPTR
    			AND		R2, R0, #0x3						// N mod 4
				ADD		R4, R2, R4							// R4 = byte address in ICDIPTR

				/* now that we have the register address (R4) and value (R2), write to (only)
				 * the appropriate byte */
				STRB		R1, [R4]
    
    			POP		{R4-R5, PC}



    .end
				
