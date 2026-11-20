module trivial_rotator #(
    parameter integer DATA_W = 16
)(
    input  wire signed [DATA_W-1:0] x_re,
    input  wire signed [DATA_W-1:0] x_im,
    input  wire        [1:0]        mode,
    output reg  signed [DATA_W-1:0] y_re,
    output reg  signed [DATA_W-1:0] y_im
);

    localparam signed [DATA_W-1:0] MIN_VALUE =
        {1'b1, {(DATA_W-1){1'b0}}};
    localparam signed [DATA_W-1:0] MAX_VALUE =
        {1'b0, {(DATA_W-1){1'b1}}};

    wire signed [DATA_W-1:0] neg_re;
    wire signed [DATA_W-1:0] neg_im;

    // Negating MIN_VALUE is the only result outside the signed range.
    assign neg_re = (x_re == MIN_VALUE) ? MAX_VALUE : -x_re;
    assign neg_im = (x_im == MIN_VALUE) ? MAX_VALUE : -x_im;

    always @(*) begin
        case (mode)
            2'b01: begin  
                y_re = x_im;
                y_im = neg_re;
            end

            2'b10: begin 
                y_re = neg_re;
                y_im = neg_im;
            end

            2'b11: begin  
                y_re = neg_im;
                y_im = x_re;
            end

            default: begin  
                y_re = x_re;
                y_im = x_im;
            end
        endcase
    end
endmodule
