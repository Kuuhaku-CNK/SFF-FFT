module r2_butterfly #(
    parameter integer DATA_W = 16
)(
    input  wire                     sel_add,

    input  wire signed [DATA_W-1:0] a_re,
    input  wire signed [DATA_W-1:0] a_im,

    input  wire signed [DATA_W-1:0] b_re,
    input  wire signed [DATA_W-1:0] b_im,

    output wire signed [DATA_W-1:0]   y_re,
    output wire signed [DATA_W-1:0]   y_im
);

    wire signed [DATA_W:0] a_re_ext;
    wire signed [DATA_W:0] a_im_ext;
    wire signed [DATA_W:0] b_re_ext;
    wire signed [DATA_W:0] b_im_ext;
    wire signed [DATA_W:0] result_re;
    wire signed [DATA_W:0] result_im;

    assign a_re_ext = {a_re[DATA_W-1], a_re};
    assign a_im_ext = {a_im[DATA_W-1], a_im};
    assign b_re_ext = {b_re[DATA_W-1], b_re};
    assign b_im_ext = {b_im[DATA_W-1], b_im};

    assign result_re = sel_add ? (a_re_ext + b_re_ext)
                               : (a_re_ext - b_re_ext);
    assign result_im = sel_add ? (a_im_ext + b_im_ext)
                               : (a_im_ext - b_im_ext);

    assign y_re = result_re >>> 1;
    assign y_im = result_im >>> 1;

endmodule
