module fft128_avalon (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [2:0]  avs_address,
    input  wire        avs_read,
    input  wire        avs_write,
    input  wire [31:0] avs_writedata,
    input  wire [3:0]  avs_byteenable,
    output wire [31:0] avs_readdata,
    output wire        avs_waitrequest
);
    localparam [2:0] ADDR_CONTROL      = 3'd0;
    localparam [2:0] ADDR_STATUS       = 3'd1;
    localparam [2:0] ADDR_INPUT_COUNT  = 3'd2;
    localparam [2:0] ADDR_OUTPUT_COUNT = 3'd3;
    localparam [2:0] ADDR_DATA_IN      = 3'd4;
    localparam [2:0] ADDR_DATA_OUT     = 3'd5;

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_PRIME = 2'd1;
    localparam [1:0] STATE_RUN   = 2'd2;

    reg [1:0] state;
    reg [15:0] input_memory [0:127];
    reg [31:0] output_memory [0:127];
    reg [7:0] input_count;
    reg [7:0] output_count;
    reg [7:0] input_index;
    reg [6:0] output_write_index;
    reg [6:0] output_read_index;
    reg done;
    reg error;

    reg signed [15:0] input_read_data;
    wire signed [15:0] core_input;
    wire [6:0] input_read_address;
    wire input_read_enable;
    wire signed [15:0] core_y_re, core_y_im;
    wire core_out_valid;
    wire core_reset_n;

    reg read_pending;
    reg read_is_data;
    reg [31:0] csr_read_data;
    reg [31:0] output_read_data;

    wire busy;
    wire input_blocked;
    wire output_blocked;
    wire read_issue;
    wire read_accept;
    wire write_accept;
    wire soft_reset;
    wire input_write;

    assign busy = (state != STATE_IDLE);
    assign input_blocked = busy || (input_count == 8'd128)
                                || (output_count != 8'd0);
    assign output_blocked = (avs_address == ADDR_DATA_OUT)
                         && (output_count == 8'd0);

    assign avs_waitrequest = avs_read ? (!read_pending || output_blocked)
                          : (avs_write && avs_address == ADDR_DATA_IN
                                       && input_blocked);
    assign avs_readdata = read_is_data ? output_read_data : csr_read_data;
    assign read_issue = avs_read && !read_pending && !output_blocked;
    assign read_accept = avs_read && !avs_waitrequest;
    assign write_accept = avs_write && !avs_read && !avs_waitrequest;
    assign soft_reset = write_accept && (avs_address == ADDR_CONTROL)
                     && avs_byteenable[0] && avs_writedata[1];
    assign input_write = write_accept && (avs_address == ADDR_DATA_IN)
                      && (&avs_byteenable[1:0]);
    assign input_read_enable = (state == STATE_PRIME)
                            || ((state == STATE_RUN) && (input_index < 8'd127));
    assign input_read_address = (state == STATE_PRIME)
                             ? 7'd0 : input_index[6:0] + 7'd1;
    assign core_input = (input_index < 8'd128) ? input_read_data : 16'sd0;

    // Hold only the FFT core in reset while loading and priming a frame.
    assign core_reset_n = reset_n && (state == STATE_RUN);
    fft128 u_fft (
        .clk(clk),
        .rst_n(core_reset_n),
        .data_in(core_input),
        .y_re(core_y_re),
        .y_im(core_y_im),
        .out_valid(core_out_valid)
    );

    // Keep reset off the RAM arrays so Quartus can infer memory resources.
    always @(posedge clk) begin
        if (input_write)
            input_memory[input_count[6:0]] <= avs_writedata[15:0];

        if (input_read_enable)
            input_read_data <= input_memory[input_read_address];

        if ((state == STATE_RUN) && core_out_valid && !soft_reset)
            output_memory[output_write_index] <= {core_y_re, core_y_im};

        if (read_issue && (avs_address == ADDR_DATA_OUT))
            output_read_data <= output_memory[output_read_index];
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state              <= STATE_IDLE;
            input_count        <= 8'd0;
            output_count       <= 8'd0;
            input_index        <= 8'd0;
            output_write_index <= 7'd0;
            output_read_index  <= 7'd0;
            done               <= 1'b0;
            error              <= 1'b0;
            read_pending       <= 1'b0;
            read_is_data       <= 1'b0;
            csr_read_data      <= 32'd0;
        end else if (soft_reset) begin
            state              <= STATE_IDLE;
            input_count        <= 8'd0;
            output_count       <= 8'd0;
            input_index        <= 8'd0;
            output_write_index <= 7'd0;
            output_read_index  <= 7'd0;
            done               <= 1'b0;
            error              <= 1'b0;
            read_pending       <= 1'b0;
            read_is_data       <= 1'b0;
            csr_read_data      <= 32'd0;
        end else begin
            if (read_issue) begin
                read_pending <= 1'b1;
                read_is_data <= (avs_address == ADDR_DATA_OUT);
                case (avs_address)
                    ADDR_STATUS:
                        csr_read_data <= {27'd0, error, (output_count != 8'd0),
                                          (input_count == 8'd128), done, busy};
                    ADDR_INPUT_COUNT:
                        csr_read_data <= {24'd0, input_count};
                    ADDR_OUTPUT_COUNT:
                        csr_read_data <= {24'd0, output_count};
                    default:
                        csr_read_data <= 32'd0;
                endcase
            end else if (read_accept) begin
                read_pending <= 1'b0;
            end

            if (read_accept && read_is_data) begin
                output_count <= output_count - 8'd1;
                output_read_index <= output_read_index + 7'd1;
            end

            case (state)
                STATE_PRIME:
                    state <= STATE_RUN;
                STATE_RUN: begin
                    if (input_index < 8'd128)
                        input_index <= input_index + 8'd1;

                    if (core_out_valid) begin
                        output_write_index <= output_write_index + 7'd1;
                        if (output_write_index == 7'd127) begin
                            state <= STATE_IDLE;
                            output_count <= 8'd128;
                            output_read_index <= 7'd0;
                            done <= 1'b1;
                        end
                    end
                end
                default:
                    state <= STATE_IDLE;
            endcase

            if (write_accept) begin
                case (avs_address)
                    ADDR_CONTROL: begin
                        if (avs_byteenable[0]) begin
                            if (avs_writedata[2]) begin
                                done <= 1'b0;
                                error <= 1'b0;
                            end
                            if (avs_writedata[0]) begin
                                if (!busy && (input_count == 8'd128)
                                          && (output_count == 8'd0)) begin
                                    state <= STATE_PRIME;
                                    input_count <= 8'd0;
                                    input_index <= 8'd0;
                                    output_write_index <= 7'd0;
                                    output_read_index <= 7'd0;
                                    done <= 1'b0;
                                end else begin
                                    error <= 1'b1;
                                end
                            end
                        end
                    end
                    ADDR_DATA_IN: begin
                        if (&avs_byteenable[1:0])
                            input_count <= input_count + 8'd1;
                        else
                            error <= 1'b1;
                    end
                    default:
                        error <= 1'b1;
                endcase
            end
        end
    end
endmodule
