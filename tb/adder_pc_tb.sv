module adder_pc_tb;

    logic [31:0] a;
    logic [31:0] sum;

    // Instantiate the module under test
    adder_pc dut (
        .a(a),
        .sum(sum)
    );

    initial begin
        // Test 1: starting PC
        a = 32'd0;
        
        #10;
        
        if (sum != 32'd4) $error("Test 1 failed: expected 4, got %0d", sum);

        // Test 2: normal increment
        a = 32'd4;
        
        #10;
        
        if (sum != 32'd8) $error("Test 2 failed: expected 8, got %0d", sum);

        // Test 3: overflow wraparound
        a = 32'hFFFFFFFC;
        
        #10;
        
        if (sum != 32'h00000000) $error("Test 3 failed: expected 0, got %0h", sum);

        $display("adder_pc_tb finished.");
        
        $finish;
    end

endmodule