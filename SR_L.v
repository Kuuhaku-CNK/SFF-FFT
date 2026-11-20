module SR_L #(
    parameter integer DATA_W = 32,
    parameter integer LENGTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [DATA_W-1:0] data_in,
    output wire [DATA_W-1:0] data_out
);

    wire [DATA_W-1:0] stage_data [0:LENGTH];

    assign stage_data[0] = data_in;
    assign data_out = stage_data[LENGTH];

    genvar i;
    generate
        for (i = 0; i < LENGTH; i = i + 1) begin : stages
            shift_register #(
                .DATA_W(DATA_W)
            ) u_register (
                .clk      (clk),
                .rst_n    (rst_n),
                .data_in  (stage_data[i]),
                .data_out (stage_data[i+1])
            );
        end
    endgenerate

endmodule