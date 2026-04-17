

module tb_bin_to_gray;

    reg  [2:0] bin;
    wire [2:0] gray;

    bin_to_gray_3bit dut (.bin(bin), .gray(gray));

    initial begin
        $dumpfile("bin_to_gray.vcd");
        $dumpvars(0,bin, gray);

        $monitor("Time=%0t | bin=%b | gray=%b", $time, bin, gray);

        bin = 3'b000; #5;
        bin = 3'b001; #5;
        bin = 3'b010; #5;
        bin = 3'b011; #5;
        bin = 3'b100; #5;
        bin = 3'b101; #5;
        bin = 3'b110; #5;
        bin = 3'b111; #5;

        $finish;
    end

endmodule