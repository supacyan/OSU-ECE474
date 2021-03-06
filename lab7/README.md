# ECE 474       Homework 7
### Digital Clock
-----------------------------------------------------

Introduction:

In this homework, we will write verilog code for digital clock.

Work to do:

1. Write your clock module as template shown below:
```verilog
module clock(
  input             reset_n,             //reset pin
  input             clk_1sec,            //1 sec clock
  input             clk_1ms,             //1 mili sec clock
  input             mil_time,            //mil time pin
  output reg [6:0]  segment_data,        // output 7 segment data
  output reg [2:0]  digit_select         // digit select
  );
```
2. Simulate clock behaviour using dofile.

What to turn in:
  Tar file of your code. It should have a shell script which simulates
  the clock 

Grading
  -Correct operation of clock                   -90%
  -Code cleanliness, coding efficiency, style   -10%

## RTL schematic created by Chauncey Yan with DigiKey Schemit

[PDF version](lab7.pdf)
![](lab7-1.png)
