// addr selects exp(-j * 2*pi * addr/128) in the project's Q1.15 ROM.
module fft_twiddle_rotate (
    input  wire        rst_n,
    input  wire [6:0]  addr,
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    wire signed [15:0] w_re, w_im;

    twiddle_rom_128 u_rom (
        .rst_n(rst_n), .in_valid(1'b1), .addr(addr),
        .out_valid(), .tw_re(w_re), .tw_im(w_im)
    );

    // Q8.8 data * Q1.15 coefficient: complex_mult removes 15 fractional bits.
    complex_mult u_mult (
        .x_re(data_in[31:16]), .x_im(data_in[15:0]),
        .w_re(w_re), .w_im(w_im),
        .y_re(data_out[31:16]), .y_im(data_out[15:0])
    );
endmodule
