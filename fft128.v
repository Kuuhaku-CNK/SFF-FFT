// Continuous real-input FFT. Input and output components use signed Q8.8.
// Present x[0] before the first rising edge after reset, then one sample/clock.
// Results are scaled by 1/128 and emitted in 7-bit bit-reversed bin order.
// out_valid qualifies the combinational result before it is sampled at a clock edge.
module fft128 (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] data_in,
    output wire signed [15:0] y_re,
    output wire signed [15:0] y_im,
    output wire               out_valid
);
    wire [6:0] sel_mux, sel_add;
    wire [1:0] rot_mode_s1, rot_mode_s3, rot_mode_s5;
    wire [6:0] k_w128;
    wire [4:0] k_w32;
    wire [2:0] k_w8;

    fft128_controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .sel_mux(sel_mux),
        .sel_add(sel_add),
        .rot_mode_s1(rot_mode_s1),
        .rot_mode_s3(rot_mode_s3),
        .rot_mode_s5(rot_mode_s5),
        .k_w128(k_w128),
        .k_w32(k_w32),
        .k_w8(k_w8),
        .out_valid(out_valid)
    );

    fft128_datapath u_datapath (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .sel_mux(sel_mux),
        .sel_add(sel_add),
        .rot_mode_s1(rot_mode_s1),
        .rot_mode_s3(rot_mode_s3),
        .rot_mode_s5(rot_mode_s5),
        .k_w128(k_w128),
        .k_w32(k_w32),
        .k_w8(k_w8),
        .y_re(y_re),
        .y_im(y_im)
    );
endmodule
