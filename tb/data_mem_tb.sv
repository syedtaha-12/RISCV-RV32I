module data_mem_tb;

    logic        clk;
    logic        we;
    logic [31:0] addr;
    logic [1:0]  size;
    logic [31:0] write_data;
    logic [31:0] read_data;

    // Instantiate the module under test
    data_mem #(.MEM_SIZE(256)) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .size(size),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generator: toggle clk every 5 time units -> 10-unit period
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we  = 0;

        // ---------- Test 1: write and read back a WORD ----------
        addr       = 32'd0;
        size       = 2'b10;         // word
        write_data = 32'hDEADBEEF;
        we         = 1;
        
        @(posedge clk);             // wait for one clock edge so the write happens
        
        we = 0;
        
        #1;                         // small delay after the edge so read_data settles
        
        if (read_data === 32'hDEADBEEF)
            $display("PASS: word write/read at addr=0 -> %h", read_data);
        else
            $display("FAIL: word write/read at addr=0 -> got %h, expected DEADBEEF", read_data);

        // ---------- Test 2: write and read back a HALFWORD ----------
        addr       = 32'd10;
        size       = 2'b01;         // halfword
        write_data = 32'h0000ABCD;  // only lowest 16 bits matter
        we         = 1;
        
        @(posedge clk);
        
        we = 0;
        
        #1;
        
        if (read_data === 32'h0000ABCD)
            $display("PASS: halfword write/read at addr=10 -> %h", read_data);
        else
            $display("FAIL: halfword write/read at addr=10 -> got %h, expected 0000ABCD", read_data);

        // ---------- Test 3: write and read back a BYTE ----------
        addr       = 32'd20;
        size       = 2'b00;         // byte
        write_data = 32'h000000EF;  // only lowest 8 bits matter
        we         = 1;
        
        @(posedge clk);
        
        we = 0;
        #1;
        
        if (read_data === 32'h000000EF)
            $display("PASS: byte write/read at addr=20 -> %h", read_data);
        else
            $display("FAIL: byte write/read at addr=20 -> got %h, expected 000000EF", read_data);

        // ---------- Test 4: write-enable OFF should NOT write ----------
        addr       = 32'd30;
        size       = 2'b10;
        write_data = 32'hCAFEF00D;
        we         = 1;
        @(posedge clk);
        we = 0;
        #1;
        // (address 30 now definitely holds CAFEF00D)

        
        write_data = 32'hFFFFFFFF;
        we         = 0;
        @(posedge clk);
        #1;

        if (read_data === 32'hCAFEF00D)
            $display("PASS: we=0 correctly blocked write, original value preserved");
        else
            $display("FAIL: got %h, expected original value CAFEF00D to persist", read_data);

        $finish;
    end

endmodule