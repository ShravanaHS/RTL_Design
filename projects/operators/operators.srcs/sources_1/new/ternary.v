module ternary(a,b,g,l,e);
  input a,b;
  output g,l,e;
  
  assign g = (a)?((b)?(1'b0):(1'b1)):(1'b0);
  assign l = (b)?((a)?(1'b0):(1'b1)):(1'b0);
  assign e = (a)?((b)?(1'b1):(1'b0)):((b)?(1'b0):(1'b1));
  
endmodule