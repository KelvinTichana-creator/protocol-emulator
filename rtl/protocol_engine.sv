module protocol_engine (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] gpio_in,
    output logic [7:0] gpio
);

    logic [7:0] pc;
    logic       waiting;
    logic [7:0] wait_counter;
    logic [7:0] input_reg;

    logic [7:0] data_reg;
    logic       data_empty;
    logic       data_bit;
    logic [3:0] bits_remaining;

    logic [15:0] program_memory [0:255];
    logic [3:0] opcode;
    logic [7:0] operand;

    localparam logic [3:0] OP_NOP         = 4'b0000;
    localparam logic [3:0] OP_SET         = 4'b0001;
    localparam logic [3:0] OP_CLR         = 4'b0010;
    localparam logic [3:0] OP_WAIT        = 4'b0011;
    localparam logic [3:0] OP_JMP         = 4'b0100;
    localparam logic [3:0] OP_READ        = 4'b0101;
    localparam logic [3:0] OP_JNZ         = 4'b0110;
    localparam logic [3:0] OP_HALT        = 4'b0111;
    localparam logic [3:0] OP_TEST        = 4'b1000;
    localparam logic [3:0] OP_SHIFT_TX    = 4'b1001;
    localparam logic [3:0] OP_LOAD_DATA   = 4'b1010;
    localparam logic [3:0] OP_WRITE_BIT   = 4'b1011;
    localparam logic [3:0] OP_SHIFT_WRITE = 4'b1100;

    assign opcode  = program_memory[pc][15:12];
    assign operand = program_memory[pc][7:0];

    // UART TX demo: send 0xB2 LSB-first using reversed data.
    initial begin
        program_memory[0]  = {OP_LOAD_DATA,   4'b0000, 8'b01001101};
        program_memory[1]  = {OP_SET,         4'b0000, 8'h01};
        program_memory[2]  = {OP_CLR,         4'b0000, 8'h01};
        program_memory[3]  = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[4]  = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[5]  = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[6]  = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[7]  = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[8]  = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[9]  = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[10] = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[11] = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[12] = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[13] = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[14] = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[15] = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[16] = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[17] = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[18] = {OP_SHIFT_WRITE, 4'b0000, 8'h01};
        program_memory[19] = {OP_WAIT,        4'b0000, 8'h04};

        program_memory[20] = {OP_SET,         4'b0000, 8'h01};
        program_memory[21] = {OP_WAIT,        4'b0000, 8'h04};
        program_memory[22] = {OP_HALT,        4'b0000, 8'h00};
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pc             <= 8'h00;
            gpio           <= 8'h00;
            waiting        <= 1'b0;
            wait_counter   <= 8'h00;
            input_reg      <= 8'h00;
            data_reg       <= 8'h00;
            data_empty     <= 1'b1;
            data_bit       <= 1'b0;
            bits_remaining <= 4'd0;
        end
        else if (waiting && (wait_counter > 8'd1)) begin
            // A full waiting interval elapses on this edge.
            wait_counter <= wait_counter - 1'b1;
        end
        else begin
            // If waiting with counter == 1, the delay completes now.
            // The next instruction executes on this same edge.
            if (waiting) begin
                waiting      <= 1'b0;
                wait_counter <= 8'd0;
            end

            case (opcode)
                OP_NOP: begin
                    pc <= pc + 1'b1;
                end

                OP_SET: begin
                    gpio <= gpio | operand;
                    pc   <= pc + 1'b1;
                end

                OP_CLR: begin
                    gpio <= gpio & ~operand;
                    pc   <= pc + 1'b1;
                end

                OP_JMP: begin
                    pc <= operand;
                end

                OP_WAIT: begin
                    pc <= pc + 1'b1;

                    if (operand == 8'd0) begin
                        wait_counter <= 8'd0;
                        waiting      <= 1'b0;
                    end
                    else begin
                        wait_counter <= operand;
                        waiting      <= 1'b1;
                    end
                end

                OP_READ: begin
                    input_reg <= gpio_in;
                    pc        <= pc + 1'b1;
                end

                OP_JNZ: begin
                    if (input_reg != 8'h00)
                        pc <= operand;
                    else
                        pc <= pc + 1'b1;
                end

                OP_HALT: begin
                    pc <= pc;
                end

                OP_TEST: begin
                    input_reg <= gpio_in & operand;
                    pc        <= pc + 1'b1;
                end

                OP_LOAD_DATA: begin
                    if (data_empty) begin
                        data_reg       <= operand;
                        bits_remaining <= 4'd8;
                        data_empty     <= 1'b0;
                        pc             <= pc + 1'b1;
                    end
                end

                OP_SHIFT_TX: begin
                    if (!data_empty) begin
                        data_bit <= data_reg[7];
                        data_reg <= data_reg << 1;

                        if (bits_remaining == 4'd1) begin
                            bits_remaining <= 4'd0;
                            data_empty     <= 1'b1;
                        end
                        else begin
                            bits_remaining <= bits_remaining - 1'b1;
                        end

                        pc <= pc + 1'b1;
                    end
                end

                OP_WRITE_BIT: begin
                    if (data_bit)
                        gpio <= gpio | operand;
                    else
                        gpio <= gpio & ~operand;

                    pc <= pc + 1'b1;
                end

                OP_SHIFT_WRITE: begin
                    if (!data_empty) begin
                        // Drive GPIO from the pre-shift MSB.
                        data_bit <= data_reg[7];
                        data_reg <= data_reg << 1;

                        if (bits_remaining == 4'd1) begin
                            bits_remaining <= 4'd0;
                            data_empty     <= 1'b1;
                        end
                        else begin
                            bits_remaining <= bits_remaining - 1'b1;
                        end

                        if (data_reg[7])
                            gpio <= gpio | operand;
                        else
                            gpio <= gpio & ~operand;

                        pc <= pc + 1'b1;
                    end
                end

                default: begin
                    pc <= pc + 1'b1;
                end
            endcase
        end
    end

endmodule
