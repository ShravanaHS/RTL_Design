

module mux4x1(i0, i1, i2, i3 ,s0, s1 ,y);
  input i0,i1, i2, i3;
  output y;
  input  s0, s1;
  wire w1,w2;
  
  mux2x1 mux1(.i1(i0), .i2(i1), .s(s0), .y(w1));
  mux2x1 mux2(.i1(i2), .i2(i3), .s(s0), .y(w2));
  mux2x1 mux3(.i1(w1), .i2(w2), .s(s1), .y(y));
    
endmodule

