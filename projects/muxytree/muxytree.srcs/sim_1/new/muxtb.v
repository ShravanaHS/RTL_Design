module mux_ttb;

  reg [15:0] i;
  reg [3:0] s;
  wire y;

  integer k;

  mux16x1 uut (.i(i), .s(s), .y(y));

  initial begin
    for(k = 0; k < 32; k = k + 1) begin   // reduced for sanity
      {i, s} = k;
      #5;
    end
  end

  initial begin
    $monitor("time=%0t, i=%b, s=%b, y=%b", $time, i, s, y);
  end

endmodule