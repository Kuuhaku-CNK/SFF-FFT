module shift_register #(
    parameter integer DATA_W = 16
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire [DATA_W-1:0]  data_in,
    output reg  [DATA_W-1:0]  data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_W{1'b0}};
        else
            data_out <= data_in;
    end

endmodule
