module dec3x8_tb;

  reg [2:0] a;
  wire [7:0] y;

  integer i;

  dec3x8 uut (.a(a), .y(y));

  initial begin
    $monitor("time=%0t  a=%b  y=%b", $time, a, y);
  end

  initial begin
    for(i = 0; i < 8; i = i + 1) begin
      a = i;
      #5;
    end
  end
initial begin
  $dumpfile("dum.vcd");
  $dumpvars(0,a,y);
end
endmodule