module mux2x1 (i, s, y);
  input [1:0]i;
  output y;
  input s;
  
  assign y = (s==0)? i[0] : i[1];
endmodule
    