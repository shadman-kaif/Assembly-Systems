#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

//Initial Function Declarations
volatile int pixel_buffer_start; //Global Variable
void clear_screen();
void draw_box(int x, int y, short int box_color);
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);
void wait_for_vsync();

//Used to swap the values of x and y when requires in draw_line function
void swap(int *x, int *y){
	int temp = *x;
    *x = *y;
    *y = temp;   
}


int main(void){
    volatile int* pixel_ctrl_ptr = (int*)0xFF203020;
    volatile int* back_buffer_ptr = (int*)0xFF203024;
	
	// Variables required
	int N = 8; //Number of vertices
	short int color[6] = {0xF800, 0x07E0, 0x001F, 0xFFE0, 0xF81F, 0x07FF};
	short int box_color[N];
	int dx_box[N], dy_box[N], x_box[N], y_box[N];

    //For each vertex choose colour and position
	for(int i = 0; i < N; i++){
		box_color[i] = color[(rand() % 6)];
		dx_box[i] = ((rand() % 2)*2) - 1;
		dy_box[i] = ((rand() % 2)*2) - 1;
		x_box[i] = rand() % 320;
		y_box[i] = rand() % 240;	
	}

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(back_buffer_ptr) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(back_buffer_ptr) = 0xC0000000;
    pixel_buffer_start = *(back_buffer_ptr); // we draw on the back buffer

    while (1)
    {
		/* Erase any boxes and lines that were drawn in the last iteration */
        clear_screen();
		
        //Code for drawing the boxes and lines
		for(int i = 0; i < N; i++){
			//Drawing 2 x 2 boxes and the lines connecting them
			draw_box(x_box[i], y_box[i], box_color[i]);
			draw_line(x_box[i], y_box[i], x_box[(i+1)%N], y_box[(i+1)%N], box_color[i]);
			
            if(x_box[i] <= 0) {
                dx_box[i] = 1;
            }

            if (x_box[i] >= 319){
                dx_box[i] = -1;
            } 

			if(y_box[i] <= 0) {
                dy_box[i] = 1;
            }

            if (y_box[i] >= 239){
                dy_box[i] = -1;
            }

            x_box[i] = x_box[i] + dx_box[i];
			y_box[i] = y_box[i] + dy_box[i];
		}
		
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(back_buffer_ptr); // new back buffer
    }
}

void wait_for_vsync(){
    volatile int* pixel_ctrl_ptr = (int*)0xFF203020;
    volatile int* status = (int*)0xFF20302C;

    *pixel_ctrl_ptr = 1;

    //Keep reading the status until Status S = 1
    while ((*status & 0x01) != 0){
        status = status;
    }

    //Exit when Status S is 1
    return;
}

//Drawing the 8 vertices of the box with their colour
void draw_box(int x, int y, short int box_color){
	plot_pixel(x, y, box_color);
	plot_pixel(x + 1, y, box_color);
	plot_pixel(x + 2, y, box_color);
	plot_pixel(x, y + 1, box_color);
	plot_pixel(x + 1, y + 2, box_color);
	plot_pixel(x + 2, y + 1, box_color);
	plot_pixel(x, y + 2, box_color);
	plot_pixel(x + 1, y + 1, box_color);
	plot_pixel(x + 2, y + 2, box_color);
}

void clear_screen() {
	int x, y;
	for (x = 0; x < 320; x++){
		for (y = 0; y < 240; y++){
			plot_pixel(x, y, 0x0000);
		}
	}
}

void draw_line(int x0, int y0, int x1, int y1, short int color){
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);

	if (is_steep){
		swap(&x0, &y0);
		swap(&x1, &y1);
	}

	if (x0 > x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
	}

	int deltax = x1 - x0;
	int deltay = y1 - y0;

	if (deltay < 0){
		deltay = -deltay;
	}

	//The error variable takes into account the relative difference between 
	//the width (deltax) and height of the line (deltay) in deciding how often y 
	//should beincremented. 
	int error = -(deltax / 2);

	int y = y0;
	int y_step;

	if (y0 < y1){
		y_step = 1;
	}

	else{
		y_step = -1;
	}

	for (int x = x0; x <= x1; x++){
		if (is_steep){
			plot_pixel(y, x, color);
		}
		else{
			plot_pixel(x, y, color);
		}

		error = error + deltay;

		if (error >= 0){
			y = y + y_step;
			error = error - deltax;
		}
	}
}

void plot_pixel(int x, int y, short int line_color){
	*(short int*)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}