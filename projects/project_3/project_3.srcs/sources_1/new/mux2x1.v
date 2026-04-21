
 
module mux2x1(i1, i2, s, y);
  input i1, i2;
  input s;
  output y;
  
  assign y = (s==0)? i1:i2;
  
endmodule