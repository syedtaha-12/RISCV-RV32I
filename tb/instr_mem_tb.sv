module instr_mem_tb;

    logic [31:0] addr;
    logic [31:0] instr_out;

    // Instantiate the module under test
    instr_mem #(.MEM_SIZE(256)) dut (
        .addr(addr),
        .instr_out(instr_out)
    );

    initial begin
        // Safety timeout in case something hangs
        #1000;
        $display("ERROR: Testbench timed out");
        $finish;
    end

    initial begin
        // Test 1: address 0 -> expect 32'h12345678
        addr = 32'd0;
        
        #10; // wait for the combinational logic to settle
        
        if (instr_out === 32'h12345678)
            $display("PASS: addr=0 -> instr_out=%h", instr_out);
        else
            $display("FAIL: addr=0 -> got %h, expected 12345678", instr_out);

        // Test 2: address 4 -> expect 32'hDDCCBBAA
        addr = 32'd4;
        #10;
        if (instr_out === 32'hDDCCBBAA)
            $display("PASS: addr=4 -> instr_out=%h", instr_out);
        else
            $display("FAIL: addr=4 -> got %h, expected DDCCBBAA", instr_out);

        // Test 3: edge case - last valid address (252, since 252+3=255 is the last byte)
        addr = 32'd252;
        #10;
        if (instr_out === 32'hABCDEFAB)
            $display("PASS: addr=252 -> instr_out=%h", instr_out);
        else
            $display("FAIL: addr=252 -> got %h, expected ABCDEFGH", instr_out);

        $display("All tests completed");
        $finish;
    end

endmodule