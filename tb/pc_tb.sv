`timescale 1ns/1ps

module pc_tb;

    logic reset;
    logic clk;
    logic [31:0] pc_in;
    logic [31:0] pc_out;

    pc dut (
        .reset  (reset),
        .clk    (clk),
        .pc_in  (pc_in),
        .pc_out (pc_out)
    );

    // Generate a clock
    initial begin
        clk = 1'b0;

        forever begin
            #5;
            clk = ~clk;
        end
    end

    // Apply test inputs
    initial begin

        // Give all inputs initial values
        reset = 1'b0;
        pc_in = 32'd0;

        // Test asynchronous reset
        #2;
        reset = 1'b1;

        #1;

        if (pc_out !== 32'd0)
            $error(
                "Reset failed: expected 0, got %0d",
                pc_out
            );

        reset = 1'b0;

        // Test loading 4
        pc_in = 32'd4;

        @(posedge clk);
        #1;

        if (pc_out !== 32'd4)
            $error(
                "PC load failed: expected 4, got %0d",
                pc_out
            );

        // Test loading 8
        pc_in = 32'd8;

        @(posedge clk);
        #1;

        if (pc_out !== 32'd8)
            $error(
                "PC load failed: expected 8, got %0d",
                pc_out
            );

        // Test loading another value
        pc_in = 32'h12345678;

        @(posedge clk);
        #1;

        if (pc_out !== 32'h12345678)
            $error(
                "PC load failed: expected 12345678, got %h",
                pc_out
            );

        // Test reset again
        reset = 1'b1;

        #1;

        if (pc_out !== 32'd0)
            $error(
                "Second reset failed: expected 0, got %0d",
                pc_out
            );

        $display("All PC tests completed.");
        $stop;

    end

endmodule