
module dec3x8 (a, y);

  input [2:0] a;
  output [7:0] y;
  wire [3:0] en;   

  dec2x4 msbenable (.a({a[2], 1'b0}), .en(1'b1), .y(en));

  dec2x4 d0 (.a(a[1:0]), .en(en[0]), .y(y[3:0]));
  dec2x4 d1 (.a(a[1:0]), .en(en[2]), .y(y[7:4]));

endmodule