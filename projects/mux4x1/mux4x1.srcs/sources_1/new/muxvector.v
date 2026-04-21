
module mux4x1(i, s, y);
  input [3:0]i;
  output y;
  input  [1:0]s;
  wire [1:0]w;
  
  mux2x1 mux1(.i(i[1:0]), .s(s[0]), .y(w[0]));
  mux2x1 mux2(.i(i[3:2]), .s(s[0]), .y(w[1]));
  mux2x1 mux3(.i(w[1:0]), .s(s[1]), .y(y));
    
endmodule

//* vector