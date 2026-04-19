`timescale 1ns / 1ps

module fa_tb;

    // 1. Declare testbench signals
    // Reg for inputs (so we can drive them in the initial block)
    reg  A;
    reg  B;
    reg  C;
    
    // Wire for outputs (so we can observe them)
    wire Sum;
    wire Carry;

    // Loop variable
    integer i;

    // 2. Instantiate the chip EXACTLY as named in your RTL
    // We map your lowercase RTL ports (.a) to our uppercase TB signals (A)
    Fulladder uut (
        .a(A),
        .b(B),
        .c(C),
        .sum(Sum),
        .carry(Carry)
    );

    // 3. Setup Waveforms and Console Monitor
    initial begin
        // NO quotes inside the dumpvars arguments!
        $dumpfile("dumpfile.vcd");
      $dumpvars(0, A,B,C,Sum,Carry); 
        
        $display("===========================");
        $display("Time | A B C | Sum Carry");
        $display("===========================");
        $monitor("%40t | %b %b %b |   %b     %b", $time, A, B, C, Sum, Carry);
    end

    // 4. The Stimulus (Driving the 0s and 1s)
    initial begin
        for(i = 0; i < 8; i = i + 1) begin
            // Explicitly grab the bottom 3 bits of 'i' to prevent truncation warnings
            {A, B, C} = i[2:0];
            
            // Wait 10ns for the physical gates to evaluate
            #10; 
        end
        
        // Wait 10ns after the last test, then cleanly kill the simulation
        #10;
        $display("===========================");
        $display("Simulation Complete!");
        $finish;
    end

endmodule