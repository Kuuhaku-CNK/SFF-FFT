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

    wire signed [DATA_W:0] a_re_mod;
    wire signed [DATA_W:0] a_im_mod;
    wire sub;

    assign sub = ~sel_add;
    assign a_re_mod = a_re_ext ^ {(DATA_W+1){sub}};
    assign a_im_mod = a_im_ext ^ {(DATA_W+1){sub}};

    wire signed [DATA_W:0] carry_in;
    assign carry_in = {{DATA_W{1'b0}}, sub};

    assign result_re = b_re_ext + a_re_mod + carry_in;
    assign result_im = b_im_ext + a_im_mod + carry_in;

    assign y_re = result_re >>> 1;
    assign y_im = result_im >>> 1;

endmodule
