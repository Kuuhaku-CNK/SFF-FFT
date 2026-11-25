// Control for the pipelined SFF datapath.
// Present x[0] before the first rising edge after rst_n is released,
// then present the next sample every clock without gaps between frames.
// Outputs are combinational datapath results, qualified by out_valid.
module fft128_controller (
    input  wire       clk,
    input  wire       rst_n,
    output wire [6:0] sel_mux,
    output wire [6:0] sel_add,
    output wire [1:0] rot_mode_s1,
    output wire [1:0] rot_mode_s3,
    output wire [1:0] rot_mode_s5,
    output reg  [6:0] k_w128,
    output reg  [4:0] k_w32,
    output reg  [2:0] k_w8,
    output reg        out_valid
);
    // Cumulative register latency at each stage input, in FFT clocks.
    localparam [6:0] LATENCY_S2 = 7'd1;
    localparam [6:0] LATENCY_S3 = 7'd3;
    localparam [6:0] LATENCY_S4 = 7'd4;
    localparam [6:0] LATENCY_S5 = 7'd6;
    localparam [6:0] LATENCY_S6 = 7'd7;
    localparam [6:0] LATENCY_S7 = 7'd9;
    localparam [7:0] FIRST_RESULT_CYCLE = 8'd127 + {1'b0, LATENCY_S7};

    reg [7:0] cycle_count;
    wire [6:0] count_s1 = cycle_count[6:0];
    wire [6:0] count_s2 = count_s1 - LATENCY_S2;
    wire [6:0] count_s3 = count_s1 - LATENCY_S3;
    wire [6:0] count_s4 = count_s1 - LATENCY_S4;
    wire [6:0] count_s5 = count_s1 - LATENCY_S5;
    wire [6:0] count_s6 = count_s1 - LATENCY_S6;
    wire [6:0] count_s7 = count_s1 - LATENCY_S7;
    wire [6:0] phase_s1, phase_s2_next, phase_s3;
    wire [6:0] phase_s4, phase_s5, phase_s6;
    reg  [6:0] k_w128_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 8'd0;
            out_valid   <= 1'b0;
            k_w128      <= 7'd0;
        end else begin
            cycle_count <= cycle_count + 8'd1;
            k_w128      <= k_w128_next;
            if (cycle_count == FIRST_RESULT_CYCLE - 8'd1)
                out_valid <= 1'b1;
        end
    end

    // Bus bit 0 controls stage 1, whose two delays each have length 64.
    assign sel_mux = {count_s7[0], count_s6[1], count_s5[2], count_s4[3],
                      count_s3[4], count_s2[5], count_s1[6]};
    assign sel_add = sel_mux;

    // Output positions modulo 128, aligned to the first result of each stage.
    assign phase_s1 = count_s1 - 7'd64;
    // Decode W128 for the next cycle so the ROM sees a registered address.
    assign phase_s2_next = count_s2 - 7'd95;
    assign phase_s3 = count_s3 - 7'd112;
    assign phase_s4 = count_s4 - 7'd120;
    assign phase_s5 = count_s5 - 7'd124;
    assign phase_s6 = count_s6 - 7'd126;

    // Mode 01 rotates by -j, mode 00 passes the sample through.
    assign rot_mode_s1 = (phase_s1[6:5] == 2'b11) ? 2'b01 : 2'b00;
    assign rot_mode_s3 = (phase_s3[4:3] == 2'b11) ? 2'b01 : 2'b00;
    assign rot_mode_s5 = (phase_s5[2:1] == 2'b11) ? 2'b01 : 2'b00;

    // Each radix-2^2 pair emits four groups with exponents 0, 2*r, r, 3*r.
    // Address scaling to the common W128 ROM is done in fft128_datapath.
    always @(*) begin
        case (phase_s2_next[6:5])
            2'b00: k_w128_next = 7'd0;
            2'b01: k_w128_next = {1'b0, phase_s2_next[4:0], 1'b0};
            2'b10: k_w128_next = {2'b00, phase_s2_next[4:0]};
            2'b11: k_w128_next = {1'b0, phase_s2_next[4:0], 1'b0}
                               + {2'b00, phase_s2_next[4:0]};
            default: k_w128_next = 7'd0;
        endcase

        case (phase_s4[4:3])
            2'b00: k_w32 = 5'd0;
            2'b01: k_w32 = {1'b0, phase_s4[2:0], 1'b0};
            2'b10: k_w32 = {2'b00, phase_s4[2:0]};
            2'b11: k_w32 = {1'b0, phase_s4[2:0], 1'b0}
                         + {2'b00, phase_s4[2:0]};
            default: k_w32 = 5'd0;
        endcase

        case (phase_s6[2:1])
            2'b00: k_w8 = 3'd0;
            2'b01: k_w8 = {1'b0, phase_s6[0], 1'b0};
            2'b10: k_w8 = {2'b00, phase_s6[0]};
            2'b11: k_w8 = {1'b0, phase_s6[0], 1'b0}
                        + {2'b00, phase_s6[0]};
            default: k_w8 = 3'd0;
        endcase
    end
endmodule
