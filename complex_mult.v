module complex_mult (
    input  wire signed [15:0] x_re,
    input  wire signed [15:0] x_im,
    input  wire signed [15:0] w_re,
    input  wire signed [15:0] w_im,
    output wire signed [15:0] y_re,
    output wire signed [15:0] y_im
);

    localparam signed [15:0] MAX_VALUE = 16'sh7FFF;
    localparam signed [15:0] MIN_VALUE = 16'sh8000;

    wire signed [31:0] ac, bd, ad, bc;
    wire signed [32:0] real_full, imag_full;
    wire overflow_re, overflow_im;

    assign ac = x_re * w_re;
    assign bd = x_im * w_im;
    assign ad = x_re * w_im;
    assign bc = x_im * w_re;

    assign real_full = $signed({ac[31], ac})
                     - $signed({bd[31], bd});

    assign imag_full = $signed({ad[31], ad})
                     + $signed({bc[31], bc});

    assign overflow_re =
        |(real_full[32:31] ^ {2{real_full[30]}});

    assign overflow_im =
        |(imag_full[32:31] ^ {2{imag_full[30]}});

    // Tran so duong thi lam tron max tran so am thi lam tron min
    assign y_re = overflow_re ? (real_full[32] ? MIN_VALUE : MAX_VALUE)
                               : real_full[30:15];
    assign y_im = overflow_im ? (imag_full[32] ? MIN_VALUE : MAX_VALUE)
                               : imag_full[30:15];

endmodule
