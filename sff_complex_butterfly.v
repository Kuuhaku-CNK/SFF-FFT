// Common delay lines, selector, and butterfly for stages 2 through 7.
// Each 32-bit word is {signed real Q8.8, signed imaginary Q8.8}.
module sff_complex_butterfly #(
    parameter integer SR_LENGTH = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire        sel_mux,
    input  wire        sel_add,
    output wire [31:0] data_out
);
    wire [31:0] sr1, sr2, b;

    SR_L #(.DATA_W(32), .LENGTH(SR_LENGTH)) u_sr1 (
        .clk(clk), .rst_n(rst_n), .data_in(data_in), .data_out(sr1)
    );
    SR_L #(.DATA_W(32), .LENGTH(SR_LENGTH)) u_sr2 (
        .clk(clk), .rst_n(rst_n), .data_in(sr1), .data_out(sr2)
    );

    mux2to1 u_mux_re (
        .in0(sr2[31:16]), .in1(data_in[31:16]), .sel(sel_mux), .out(b[31:16])
    );
    mux2to1 u_mux_im (
        .in0(sr2[15:0]), .in1(data_in[15:0]), .sel(sel_mux), .out(b[15:0])
    );

    r2_butterfly #(.DATA_W(16)) u_butterfly (
        .sel_add(sel_add),
        .a_re(sr1[31:16]), .a_im(sr1[15:0]),
        .b_re(b[31:16]), .b_im(b[15:0]),
        .y_re(data_out[31:16]), .y_im(data_out[15:0])
    );
endmodule
