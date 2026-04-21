`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2026 18:25:32
// Design Name: 
// Module Name: mux_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux_tb;

reg i0, i1,s;
wire y;


mux2x1 dutinit(i0,i1,s,y);
initial begin
$monitor("time_vars =%0t, i0 = %d, i1 = %d, s = %d, y = %d" , $time, i0,i1,s,y);
end
initial begin 
$dumpfile("dum.vcd");
$dumpvars(0,i0,i1,s,y);
end

initial begin
i0 = 0; i1 = 0; s = 0;
#5 i0 = 1; i1 = 0; s = 1;
#5 i0 = 1; i1 = 1; s = 1;
#5 i0 = 1; i1 = 1; s = 1;
#5 i0 = 1; i1 = 0; s = 0;

end
endmodule
