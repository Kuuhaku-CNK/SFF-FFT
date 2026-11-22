// Control for the current combinational-butterfly SFF datapath.
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
    reg [6:0] cycle_count;
    wire [6:0] phase_s1, phase_s2, phase_s3;
    wire [6:0] phase_s4, phase_s5, phase_s6;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 7'd0;
            out_valid   <= 1'b0;
        end else begin
            cycle_count <= cycle_count + 7'd1;
            // First output is valid after 64+32+16+8+4+2+1 clocks.
            if (cycle_count == 7'd126)
                out_valid <= 1'b1;
        end
    end

    // Bus bit 0 controls stage 1, whose two delays each have length 64.
    assign sel_mux = {cycle_count[0], cycle_count[1], cycle_count[2],
                      cycle_count[3], cycle_count[4], cycle_count[5],
                      cycle_count[6]};
    assign sel_add = sel_mux;

    // Output positions modulo 128, aligned to the first result of each stage.
    assign phase_s1 = cycle_count - 7'd64;
    assign phase_s2 = cycle_count - 7'd96;
    assign phase_s3 = cycle_count - 7'd112;
    assign phase_s4 = cycle_count - 7'd120;
    assign phase_s5 = cycle_count - 7'd124;
    assign phase_s6 = cycle_count - 7'd126;

    // Mode 01 rotates by -j, mode 00 passes the sample through.
    assign rot_mode_s1 = (phase_s1[6:5] == 2'b11) ? 2'b01 : 2'b00;
    assign rot_mode_s3 = (phase_s3[4:3] == 2'b11) ? 2'b01 : 2'b00;
    assign rot_mode_s5 = (phase_s5[2:1] == 2'b11) ? 2'b01 : 2'b00;

    // Each radix-2^2 pair emits four groups with exponents 0, 2*r, r, 3*r.
    // Address scaling to the common W128 ROM is done in fft128_datapath.
    always @(*) begin
        case (phase_s2[6:5])
            2'b00: k_w128 = 7'd0;
            2'b01: k_w128 = {1'b0, phase_s2[4:0], 1'b0};
            2'b10: k_w128 = {2'b00, phase_s2[4:0]};
            2'b11: k_w128 = {1'b0, phase_s2[4:0], 1'b0}
                          + {2'b00, phase_s2[4:0]};
            default: k_w128 = 7'd0;
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
