`timescale 1ns / 1ps

module Fulladder(a,b,c,sum,carry);
input a,b,c;
output sum, carry;
wire zor1, and1, and2;

//dataflow
//assign sum = a^b^c;
//assign carry = a&b;

//gatelevelcode
xor zor11(zor1,a,b);
xor zor21(sum,zor1,c);

and and11(and1,a,b);
and and21(and2,zor1,c);

or or1(carry,and1,and2);


endmodule
