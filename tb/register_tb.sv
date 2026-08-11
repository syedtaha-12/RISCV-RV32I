`timescale 1ns / 1ps

module register_tb;

    logic        clk;
    logic        we;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    int errors = 0;
    int checks = 0;

    // Behavioral model mirroring the DUT, used as the reference
    logic [31:0] model [31:0];

    register_file dut (
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // 10ns period clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Drive a write on the next rising edge, update the model too
    task automatic do_write(input logic [4:0] addr, input logic [31:0] data);
        we      = 1'b1;
        rd_addr = addr;
        rd_data = data;
        @(posedge clk);
        if (addr != 5'd0) model[addr] = data;
        #1; // let the write settle before we deassert
        we = 1'b0;
    endtask

    // Check combinational read ports against the model
    task automatic check_reads(input logic [4:0] addr1, input logic [4:0] addr2, input string tag);
        logic [31:0] expected1, expected2;
        rs1_addr = addr1;
        rs2_addr = addr2;
        #1; // allow combinational logic to settle
        expected1 = (addr1 == 5'd0) ? 32'd0 : model[addr1];
        expected2 = (addr2 == 5'd0) ? 32'd0 : model[addr2];
        checks++;
        if (rs1_data !== expected1) begin
            errors++;
            $display("FAIL [%s] rs1_addr=%0d expected=%0h got=%0h", tag, addr1, expected1, rs1_data);
        end
        if (rs2_data !== expected2) begin
            errors++;
            $display("FAIL [%s] rs2_addr=%0d expected=%0h got=%0h", tag, addr2, expected2, rs2_data);
        end
        if (rs1_data === expected1 && rs2_data === expected2) begin
            $display("PASS [%s] rs1=%0h rs2=%0h", tag, rs1_data, rs2_data);
        end
    endtask

    initial begin
        // Init
        we = 0; rd_addr = 0; rd_data = 0; rs1_addr = 0; rs2_addr = 0;
        for (int i = 0; i < 32; i++) model[i] = 32'd0;
        @(posedge clk);

        // Test 1: basic write then read back
        do_write(5'd5, 32'hDEADBEEF);
        check_reads(5'd5, 5'd0, "basic write/read");

        // Test 2: x0 always reads zero, even if a write to it is attempted
        do_write(5'd0, 32'hFFFFFFFF);
        check_reads(5'd0, 5'd0, "x0 hardwired zero");

        // Test 3: write-enable gating - no write happens when we is low
        do_write(5'd7, 32'h12345678);
        we = 1'b0;
        rd_data = 32'h02356469;
        @(posedge clk);
        #1;
        check_reads(5'd7, 5'd0, "we low blocks write");

        // Test 4: reading two different registers at once
        do_write(5'd10, 32'hAAAA0001);
        do_write(5'd20, 32'hBBBB0002);
        check_reads(5'd10, 5'd20, "dual-port simultaneous read");

        // Test 5: write then immediate read same cycle - combinational read
        // should still show the OLD value right up until the clock edge lands
        // before the clock edge, write hasn't landed yet
        do_write(5'd15, 32'hDEADF00D);
        checks++;
        rd_addr = 5'd15;
        rd_data = 32'hCAFEBEEF;
        we = 1'b1;
        rs1_addr = 5'd15;
        #1
        if (rs1_data !== model[15]) begin
            errors++;
            $display("FAIL [pre-edge read] expected=%0h got=%0h", model[15], rs1_data);
        end else begin
            $display("PASS [pre-edge read] rs1=%0h (old value, as expected)", rs1_data);
        end
        @(posedge clk);
        model[15] = 32'hCAFEBEEF;
        #1;
        we = 1'b0;
        check_reads(5'd15, 5'd0, "post-edge read shows new value");

        // Test 6: overwrite an already-written register
        do_write(5'd15, 32'h11112222);
        check_reads(5'd15, 5'd0, "overwrite existing register");

        // Summary
        $display("----------------------------------------");
        if (errors == 0)
            $display("ALL %0d CHECKS PASSED", checks);
        else
            $display("%0d OF %0d CHECKS FAILED", errors, checks);
        $display("----------------------------------------");

        $finish;
    end

endmodule