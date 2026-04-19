module mux2to1 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);

    // Dataflow ternary operator
    // If sel is 1, y gets b. If sel is 0, y gets a.
    assign y = sel ? b : a;

endmodule