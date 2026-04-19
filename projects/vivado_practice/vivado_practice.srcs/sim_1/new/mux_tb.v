`timescale 1ns / 1ps

module tb_mux2to1;

    // 1. Declare Signals
    // Inputs to DUT are 'reg' so we can drive them
    reg tb_a;
    reg tb_b;
    reg tb_sel;
    
    // Outputs from DUT are 'wire' so we can observe them
    wire tb_y;
    
    // Loop variable for exhaustive testing
    integer i;

    // 2. Instantiate the Design Under Test (DUT)
    // Make sure the module name matches EXACTLY what you named your RTL module
    mux2to1 u_dut (
        .a(tb_a),
        .b(tb_b),
        .sel(tb_sel),
        .y(tb_y)
    );

    // 3. Stimulus Generation
    initial begin
        // Print a nice header to the TCL console in Vivado
        $display("=======================================");
        $display("Time | sel  b  a | Output (y)");
        $display("=======================================");

        // Exhaustive testing: loop from 0 to 7 (all 8 combinations)
        for (i = 0; i < 8; i = i + 1) begin
            // We use concatenation to easily map the 3 bits of 'i' to our inputs
            {tb_sel, tb_b, tb_a} = i[2:0]; 
            
            // Wait 10ns for the physical gates to propagate the logic
            #10; 
            
            // Print the result for this specific combination
            $display("%40t |   %b  %b  %b |        %b", $time, tb_sel, tb_b, tb_a, tb_y);
        end

        // Wait a bit, then stop the simulation
        #20;
        $display("=======================================");
        $display("Simulation Complete!");
        $finish;
    end

endmodule