module comp_tb;
  reg a,b;
  wire g,l,e;
  integer i;
  comp1bit uut(a,b,g,l,e);
  
  initial begin
    for(i = 0; i < 4; i= i+1)
      begin
        {a,b} = i;
        #5;
      end
  end
  
  initial begin
    $monitor("time_vars = %0t, a = %d, b = %d, g = %d, l = %d, e = %d",$time, a,b,g,l,e);
  end
endmodule