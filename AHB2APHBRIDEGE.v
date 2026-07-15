//=============================================================
// Module      : ahb2apb_bridge
// Description : AHB-Lite to APB Bridge
//               - Single AHB slave interface
//               - Drives 2 APB peripherals (PSEL0 / PSEL1) via
//                 address decoding
//               - Simple 3-state FSM: IDLE -> SETUP -> ENABLE
//=============================================================

module ahb2apb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // ---------------- AHB Slave Interface ----------------
    input  wire                    HCLK,
    input  wire                    HRESETn,
    input  wire [ADDR_WIDTH-1:0]   HADDR,
    input  wire [DATA_WIDTH-1:0]   HWDATA,
    input  wire                    HWRITE,
    input  wire [1:0]              HTRANS,     // 00-IDLE 01-BUSY 10-NONSEQ 11-SEQ
    input  wire [2:0]              HSIZE,
    input  wire                    HSEL,       // this bridge selected on AHB
    output reg                     HREADYOUT,
    output reg  [DATA_WIDTH-1:0]   HRDATA,
    output reg                     HRESP,      // 0 = OKAY, 1 = ERROR

    // ---------------- APB Master Interface ----------------
    output reg  [ADDR_WIDTH-1:0]   PADDR,
    output reg  [DATA_WIDTH-1:0]   PWDATA,
    output reg                     PWRITE,
    output reg                     PENABLE,
    output reg                     PSEL0,
    output reg                     PSEL1,
    input  wire [DATA_WIDTH-1:0]   PRDATA,
    input  wire                    PREADY
);

    // ---------------- HTRANS encodings ----------------
    localparam HTRANS_IDLE   = 2'b00;
    localparam HTRANS_BUSY   = 2'b01;
    localparam HTRANS_NONSEQ = 2'b10;
    localparam HTRANS_SEQ    = 2'b11;

    // ---------------- FSM states ----------------
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ENABLE = 2'b10;

    reg [1:0] state, next_state;

    // Latched AHB address-phase info
    reg [ADDR_WIDTH-1:0] addr_latched;
    reg                   write_latched;

    // ---------------- APB address map (example) ----------------
    // Slave0 : 0x0000_0000 - 0x0000_0FFF
    // Slave1 : 0x0000_1000 - 0x0000_1FFF
    wire sel_slave0 = (addr_latched[31:12] == 20'h00000);
    wire sel_slave1 = (addr_latched[31:12] == 20'h00001);

    wire valid_transfer = HSEL & (HTRANS == HTRANS_NONSEQ || HTRANS == HTRANS_SEQ);

    // ================= State register =================
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ================= Next-state logic =================
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_transfer)
                    next_state = SETUP;
            end

            SETUP: begin
                next_state = ENABLE;
            end

            ENABLE: begin
                if (PREADY) begin
                    // Back-to-back support: if another valid transfer
                    // is already on the bus, go straight to SETUP again
                    if (valid_transfer)
                        next_state = SETUP;
                    else
                        next_state = IDLE;
                end
                else begin
                    next_state = ENABLE; // wait state
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // ================= Latch AHB address-phase signals =================
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_latched  <= {ADDR_WIDTH{1'b0}};
            write_latched <= 1'b0;
        end
        else if (state == IDLE && valid_transfer) begin
            addr_latched  <= HADDR;
            write_latched <= HWRITE;
        end
        else if (state == ENABLE && PREADY && valid_transfer) begin
            // capture next transfer's address for pipelined back-to-back
            addr_latched  <= HADDR;
            write_latched <= HWRITE;
        end
    end

    // ================= Output logic (Moore) =================
    always @(*) begin
        // Defaults
        PSEL0     = 1'b0;
        PSEL1     = 1'b0;
        PENABLE   = 1'b0;
        PWRITE    = write_latched;
        PADDR     = addr_latched;
        PWDATA    = HWDATA;
        HREADYOUT = 1'b0;
        HRESP     = 1'b0;

        case (state)
            IDLE: begin
                HREADYOUT = 1'b1;
            end

            SETUP: begin
                PSEL0   = sel_slave0;
                PSEL1   = sel_slave1;
                PENABLE = 1'b0;
                HREADYOUT = 1'b0;
            end

            ENABLE: begin
                PSEL0   = sel_slave0;
                PSEL1   = sel_slave1;
                PENABLE = 1'b1;
                HREADYOUT = PREADY;   // stall AHB master until APB slave ready
            end

            default: begin
                HREADYOUT = 1'b1;
            end
        endcase
    end

    // ================= Read data capture =================
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            HRDATA <= {DATA_WIDTH{1'b0}};
        else if (state == ENABLE && PREADY && !write_latched)
            HRDATA <= PRDATA;
    end

endmodule
