`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2026 07:50:20
// Design Name: 
// Module Name: btog_3bit
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


module bin_to_gray_3bit(bin, grey);

    input  [2:0] bin;
    output [2:0] grey;

    assign grey[2] = bin[2];
    assign grey[1] = bin[2] ^ bin[1];
    assign grey[0] = bin[1] ^ bin[0];

endmodule
