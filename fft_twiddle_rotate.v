// addr selects exp(-j * 2*pi * addr/128) in the project's Q1.15 ROM.
module fft_twiddle_rotate (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [6:0]  addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out
);
    wire signed [15:0] w_re, w_im;
    reg  signed [15:0] w_re_reg, w_im_reg;
    reg  [31:0] data_reg;
    wire [31:0] rotated;

    twiddle_rom_128 u_rom (
        .rst_n(rst_n), .in_valid(1'b1), .addr(addr),
        .out_valid(), .tw_re(w_re), .tw_im(w_im)
    );

    // Register the butterfly sample and its coefficient together.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'd0;
            w_re_reg <= 16'sd0;
            w_im_reg <= 16'sd0;
            data_out <= 32'd0;
        end else begin
            data_reg <= data_in;
            w_re_reg <= w_re;
            w_im_reg <= w_im;
            data_out <= rotated;
        end
    end

    // Q8.8 data * Q1.15 coefficient: complex_mult removes 15 fractional bits.
    complex_mult u_mult (
        .x_re(data_reg[31:16]), .x_im(data_reg[15:0]),
        .w_re(w_re_reg), .w_im(w_im_reg),
        .y_re(rotated[31:16]), .y_im(rotated[15:0])
    );
endmodule
