// Real-input datapath: data_in -> SR1 -> SR2 -> mux -> butterfly -> rotator.
// SR1 also feeds butterfly input a; data_in also feeds mux input 1.
// Control signals are supplied externally (no control unit here).
module fft_stage #(
    parameter integer SR_LENGTH = 64
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] data_in,
    input  wire               sel_mux,
    input  wire               sel_add,
    input  wire        [1:0]  rot_mode,
    output wire signed [15:0] y_re,
    output wire signed [15:0] y_im
);

    wire signed [15:0] sr1_data;
    wire signed [15:0] sr2_data;
    wire signed [15:0] mux_re;
    wire signed [15:0] butterfly_re;
    wire signed [15:0] butterfly_im;

    // Input samples are real: each SR stores only 16 bits per sample.
    SR_L #(
        .DATA_W(16),
        .LENGTH(SR_LENGTH)
    ) u_sr1 (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_in (data_in),
        .data_out(sr1_data)
    );

    SR_L #(
        .DATA_W(16),
        .LENGTH(SR_LENGTH)
    ) u_sr2 (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_in (sr1_data),
        .data_out(sr2_data)
    );

    // The source filename is mux2to1_16bit.v; its module name is mux2to1.
    // sel_mux = 0: SR2; sel_mux = 1: current input.
    mux2to1 u_mux_re (
        .in0(sr2_data),
        .in1(data_in),
        .sel(sel_mux),
        .out(mux_re)
    );

    // sel_add = 1: a + b; sel_add = 0: b - a (before scaling).
    r2_butterfly #(
        .DATA_W(16)
    ) u_butterfly (
        .sel_add(sel_add),
        .a_re   (sr1_data),
        .a_im   (16'sd0),
        .b_re   (mux_re),
        .b_im   (16'sd0),
        .y_re   (butterfly_re),
        .y_im   (butterfly_im)
    );

    // r2_butterfly scales its 17-bit sum/difference to a 16-bit sample.
    trivial_rotator #(
        .DATA_W(16)
    ) u_rotator (
        .x_re    (butterfly_re),
        .x_im    (butterfly_im),
        .mode    (rot_mode),
        .y_re    (y_re),
        .y_im    (y_im)
    );

endmodule
