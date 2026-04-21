
module mux16x1(i, s, y);
  input [15:0]i;
  input [3:0]s;
  output y;
  
  
  wire [3:0]n;
  
  mux4x1 uut1(.i(i[3:0]), .s(s[1:0]), .y(n[0]));
  mux4x1 uut2(.i(i[7:4]), .s(s[1:0]), .y(n[1]));
  mux4x1 uut3(.i(i[11:8]), .s(s[1:0]), .y(n[2]));
  mux4x1 uut4(.i(i[15:12]), .s(s[1:0]), .y(n[3]));
  mux4x1 uut5(.i(n[3:0]), .s(s[3:2]), .y(y));
  
  endmodule