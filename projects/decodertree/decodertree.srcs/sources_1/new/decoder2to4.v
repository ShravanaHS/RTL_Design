module dec2x4 (a, en, y);
  input [1:0] a;
  input en;
  output [3:0] y;
  wire na, nb;
  
  not (na, a[1]);
  not (nb, a[0]);

  and (y[0], en, na, nb);
  and (y[1], en, na, a[0]);
  and (y[2], en, a[1], nb);
  and (y[3], en, a[1], a[0]);

endmodule