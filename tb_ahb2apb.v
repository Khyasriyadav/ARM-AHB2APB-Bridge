//=============================================================
// Module      : tb_ahb2apb
// Description : Self-checking testbench for ahb2apb_bridge
//               - Drives AHB-Lite transactions (write/read)
//               - Behavioral APB slave memory model reacts
//                 to PSEL/PENABLE/PWRITE
//               - Checks HRDATA against expected values
//=============================================================
`timescale 1ns/1ps

module tb_ahb2apb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // ---------------- DUT signals ----------------
    reg                     HCLK;
    reg                     HRESETn;
    reg  [ADDR_WIDTH-1:0]   HADDR;
    reg  [DATA_WIDTH-1:0]   HWDATA;
    reg                     HWRITE;
    reg  [1:0]              HTRANS;
    reg  [2:0]              HSIZE;
    reg                     HSEL;
    wire                    HREADYOUT;
    wire [DATA_WIDTH-1:0]   HRDATA;
    wire                    HRESP;

    wire [ADDR_WIDTH-1:0]   PADDR;
    wire [DATA_WIDTH-1:0]   PWDATA;
    wire                    PWRITE;
    wire                    PENABLE;
    wire                    PSEL0;
    wire                    PSEL1;
    reg  [DATA_WIDTH-1:0]   PRDATA;
    reg                     PREADY;

    integer errors = 0;
    integer i;

    localparam HTRANS_IDLE   = 2'b00;
    localparam HTRANS_NONSEQ = 2'b10;

    // ---------------- DUT instantiation ----------------
    ahb2apb_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HADDR     (HADDR),
        .HWDATA    (HWDATA),
        .HWRITE    (HWRITE),
        .HTRANS    (HTRANS),
        .HSIZE     (HSIZE),
        .HSEL      (HSEL),
        .HREADYOUT (HREADYOUT),
        .HRDATA    (HRDATA),
        .HRESP     (HRESP),

        .PADDR     (PADDR),
        .PWDATA    (PWDATA),
        .PWRITE    (PWRITE),
        .PENABLE   (PENABLE),
        .PSEL0     (PSEL0),
        .PSEL1     (PSEL1),
        .PRDATA    (PRDATA),
        .PREADY    (PREADY)
    );

    // ---------------- Clock generation ----------------
    initial HCLK = 0;
    always #5 HCLK = ~HCLK;   // 100 MHz

    // ---------------- Behavioral APB slave memory models ----------------
    // Slave0 memory : addr[31:12] == 0
    // Slave1 memory : addr[31:12] == 1
    reg [DATA_WIDTH-1:0] mem_slave0 [0:255];
    reg [DATA_WIDTH-1:0] mem_slave1 [0:255];
    reg                  extra_wait; // toggled to inject wait-states

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            PREADY <= 1'b0;
            PRDATA <= 0;
        end
        else begin
            if ((PSEL0 || PSEL1) && PENABLE) begin
                if (extra_wait) begin
                    // inject one wait state, then ready on next cycle
                    PREADY <= 1'b1;
                end
                else begin
                    PREADY <= 1'b1;
                end

                if (PREADY) begin
                    if (PWRITE) begin
                        if (PSEL0) mem_slave0[PADDR[9:2]] <= PWDATA;
                        if (PSEL1) mem_slave1[PADDR[9:2]] <= PWDATA;
                    end
                    else begin
                        if (PSEL0) PRDATA <= mem_slave0[PADDR[9:2]];
                        if (PSEL1) PRDATA <= mem_slave1[PADDR[9:2]];
                    end
                end
            end
            else begin
                PREADY <= 1'b0;
            end
        end
    end

    // ---------------- AHB driver tasks ----------------
    task ahb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge HCLK);
            HSEL   = 1'b1;
            HADDR  = addr;
            HWRITE = 1'b1;
            HTRANS = HTRANS_NONSEQ;
            HSIZE  = 3'b010; // word
            HWDATA = data;

            // wait until HREADYOUT indicates transfer accepted/completed
            @(negedge HCLK);
            while (!HREADYOUT) @(negedge HCLK);

            HTRANS = HTRANS_IDLE;
            HSEL   = 1'b0;
            $display("[%0t] AHB WRITE addr=0x%08h data=0x%08h", $time, addr, data);
        end
    endtask

    task ahb_read(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] expected);
        begin
            @(negedge HCLK);
            HSEL   = 1'b1;
            HADDR  = addr;
            HWRITE = 1'b0;
            HTRANS = HTRANS_NONSEQ;
            HSIZE  = 3'b010;

            @(negedge HCLK);
            while (!HREADYOUT) @(negedge HCLK);

            HTRANS = HTRANS_IDLE;
            HSEL   = 1'b0;

            @(negedge HCLK); // allow HRDATA to settle (captured on the ENABLE->PREADY edge)
            if (HRDATA !== expected) begin
                $display("[%0t] ERROR: AHB READ addr=0x%08h expected=0x%08h got=0x%08h",
                           $time, addr, expected, HRDATA);
                errors = errors + 1;
            end
            else begin
                $display("[%0t] PASS : AHB READ addr=0x%08h data=0x%08h", $time, addr, HRDATA);
            end
        end
    endtask

    // ---------------- Test sequence ----------------
    initial begin
        // Init
        HRESETn = 0;
        HSEL    = 0;
        HADDR   = 0;
        HWDATA  = 0;
        HWRITE  = 0;
        HTRANS  = HTRANS_IDLE;
        HSIZE   = 3'b010;
        extra_wait = 0;

        for (i = 0; i < 256; i = i + 1) begin
            mem_slave0[i] = 0;
            mem_slave1[i] = 0;
        end

        repeat (4) @(negedge HCLK);
        HRESETn = 1;
        repeat (2) @(negedge HCLK);

        // ---- Test 1: Write/Read to Slave0 ----
        ahb_write(32'h0000_0004, 32'hDEAD_BEEF);
        ahb_read (32'h0000_0004, 32'hDEAD_BEEF);

        // ---- Test 2: Write/Read to Slave1 ----
        ahb_write(32'h0000_1008, 32'hCAFE_BABE);
        ahb_read (32'h0000_1008, 32'hCAFE_BABE);

        // ---- Test 3: Back-to-back writes then reads ----
        ahb_write(32'h0000_0010, 32'h1111_1111);
        ahb_write(32'h0000_0014, 32'h2222_2222);
        ahb_read (32'h0000_0010, 32'h1111_1111);
        ahb_read (32'h0000_0014, 32'h2222_2222);

        // ---- Test 4: Reset behavior check ----
        HRESETn = 0;
        repeat (2) @(negedge HCLK);
        HRESETn = 1;
        repeat (2) @(negedge HCLK);
        ahb_read(32'h0000_0004, 32'hDEAD_BEEF); // memory model itself isn't reset,
                                                 // this just checks bridge recovers cleanly

        // ---- Summary ----
        repeat (5) @(negedge HCLK);
        if (errors == 0)
            $display("\n==================== ALL TESTS PASSED ====================\n");
        else
            $display("\n==================== %0d TEST(S) FAILED ====================\n", errors);

        $finish;
    end

    // ---------------- Waveform dump ----------------
    initial begin
        $dumpfile("ahb2apb_tb.vcd");
        $dumpvars(0, tb_ahb2apb);
    end

endmodule
