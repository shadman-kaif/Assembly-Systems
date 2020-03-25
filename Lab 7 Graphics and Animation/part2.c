#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

//Initial Function Declarations
volatile int pixel_buffer_start; //Global Variable
void clear_screen();
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
	volatile int* pixel_ctrl_ptr = (int*) 0xFF203020;
	/* Read location of the pixel buffer from the pixel buffer controller */
	pixel_buffer_start = *pixel_ctrl_ptr;

	clear_screen();

	int x0 = 0;
    int x1 = 319;
    int y0 = 0;
    int y1 = 0;

    int yIncrement = 1;

    while (1) {
        draw_line (x0, y0, x1, y1, 0x001F); //This line is Blue
        wait_for_vsync();
        draw_line(x0, y0, x1, y1, 0x0000);

        if (y0 == 0){
            yIncrement = 1;
        }

        else if (y1 == 239){
            yIncrement = -1;
        }

        y0 = y0 + yIncrement;
        y1 = y1 + yIncrement;
    } 
	return 0;
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