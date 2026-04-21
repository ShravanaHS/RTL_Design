module mux_ttb;
  reg [3:0]i;
  reg [1:0]s;
  
  wire y;
  integer k;
mux4x1 uut (.i0(i[0]), .i1(i[1]), .i2(i[2]), .i3(i[3]), .s0(s[0]), .s1(s[1]), .y(y));
  
//   initial begin
//       i = 4'b0001; s = 2'b00;
//    #5 i = 4'b0000; s = 2'b01;
//    #5 i = 4'b1100; s = 2'b10;
//    #5 i = 4'b1010; s = 2'b11;
//    #5 i = 4'b1010; s = 2'b00;
//    #5 i = 4'b1010; s = 2'b01;
//   end
   
  initial begin
    for(k=0; k < 2**6; k = k+1)
       begin
         {i[3:0], s[1:0]} = k;
         #2;
      end
  end
  
 initial begin
   $monitor("time=%0t, i=%b, s=%b, y=%b", $time, i,s,y);
  end
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
    
    
  