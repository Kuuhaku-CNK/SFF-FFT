module fft128_datapath (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] data_in,       // real Q8.8
    input  wire        [6:0]  sel_mux,       // bit 0 = stage 1
    input  wire        [6:0]  sel_add,       // bit 0 = stage 1
    input  wire        [1:0]  rot_mode_s1,
    input  wire        [1:0]  rot_mode_s3,
    input  wire        [1:0]  rot_mode_s5,
    input  wire        [6:0]  k_w128,
    input  wire        [4:0]  k_w32,
    input  wire        [2:0]  k_w8,
    output wire signed [15:0] y_re,
    output wire signed [15:0] y_im
);
    // Complex buses pack {real[15:0], imag[15:0]}.
    wire [31:0] s1_out, s2_out, s3_out, s4_out, s5_out, s6_out;
    wire [31:0] s2_bf, s3_bf, s4_bf, s5_bf, s6_bf;

    fft_stage #(.SR_LENGTH(64)) u_stage1 (
        .clk(clk), .rst_n(rst_n), .data_in(data_in),
        .sel_mux(sel_mux[0]), .sel_add(sel_add[0]), .rot_mode(rot_mode_s1),
        .y_re(s1_out[31:16]), .y_im(s1_out[15:0])
    );

    // Stage 2: two 32-sample complex delays and W128.
    sff_complex_butterfly #(.SR_LENGTH(32)) u_stage2 (
        .clk(clk), .rst_n(rst_n), .data_in(s1_out),
        .sel_mux(sel_mux[1]), .sel_add(sel_add[1]),
        .data_out(s2_bf)
    );
    fft_twiddle_rotate u_rot_s2 (
        .rst_n(rst_n), .addr(k_w128),
        .data_in(s2_bf), .data_out(s2_out)
    );

    // Stage 3: two 16-sample complex delays and trivial rotation.
    sff_complex_butterfly #(.SR_LENGTH(16)) u_stage3 (
        .clk(clk), .rst_n(rst_n), .data_in(s2_out),
        .sel_mux(sel_mux[2]), .sel_add(sel_add[2]),
        .data_out(s3_bf)
    );
    trivial_rotator #(.DATA_W(16)) u_rot_s3 (
        .x_re(s3_bf[31:16]), .x_im(s3_bf[15:0]), .mode(rot_mode_s3),
        .y_re(s3_out[31:16]), .y_im(s3_out[15:0])
    );

    // Stage 4: two 8-sample complex delays and W32.
    sff_complex_butterfly #(.SR_LENGTH(8)) u_stage4 (
        .clk(clk), .rst_n(rst_n), .data_in(s3_out),
        .sel_mux(sel_mux[3]), .sel_add(sel_add[3]),
        .data_out(s4_bf)
    );
    fft_twiddle_rotate u_rot_s4 (
        .rst_n(rst_n), .addr({k_w32, 2'b00}),
        .data_in(s4_bf), .data_out(s4_out)
    );

    // Stage 5: two 4-sample complex delays and trivial rotation.
    sff_complex_butterfly #(.SR_LENGTH(4)) u_stage5 (
        .clk(clk), .rst_n(rst_n), .data_in(s4_out),
        .sel_mux(sel_mux[4]), .sel_add(sel_add[4]),
        .data_out(s5_bf)
    );
    trivial_rotator #(.DATA_W(16)) u_rot_s5 (
        .x_re(s5_bf[31:16]), .x_im(s5_bf[15:0]), .mode(rot_mode_s5),
        .y_re(s5_out[31:16]), .y_im(s5_out[15:0])
    );

    // Stage 6: two 2-sample complex delays and W8.
    sff_complex_butterfly #(.SR_LENGTH(2)) u_stage6 (
        .clk(clk), .rst_n(rst_n), .data_in(s5_out),
        .sel_mux(sel_mux[5]), .sel_add(sel_add[5]),
        .data_out(s6_bf)
    );
    fft_twiddle_rotate u_rot_s6 (
        .rst_n(rst_n), .addr({k_w8, 4'b0000}),
        .data_in(s6_bf), .data_out(s6_out)
    );

    // Stage 7: two 1-sample complex delays.
    sff_complex_butterfly #(.SR_LENGTH(1)) u_stage7 (
        .clk(clk), .rst_n(rst_n), .data_in(s6_out),
        .sel_mux(sel_mux[6]), .sel_add(sel_add[6]),
        .data_out({y_re, y_im})
    );
endmodule
