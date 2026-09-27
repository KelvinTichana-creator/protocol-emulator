module protocol_engine (
    input  logic       clk,
    input  logic       rst,
    input logic [7:0] gpio_in,
    output logic [7:0] gpio
);

    // Program counter
    logic [7:0] pc;

    //counter register
    logic [7:0] wait_counter;
    //store gpio_in
    logic [7:0] input_reg;
    //data register - protocol agnostic
    logic [7:0] data_reg;
    //flag when data_reg is empty (set it)
    logic       data_empty;
    //data bit to be shifted from the data_reg (shift register)
    logic       data_bit;
    logic [3:0] bits_remaining;
    // Instruction memory
    logic [15:0] program_memory [0:255];

    // Instruction fields
    logic [3:0] opcode;
    logic [7:0] operand;

    // Opcodes
    localparam logic [3:0] OP_NOP = 4'b0000;
    localparam logic [3:0] OP_SET = 4'b0001;
    localparam logic [3:0] OP_CLR = 4'b0010;
    localparam logic [3:0] OP_JMP = 4'b0100;
    localparam logic [3:0] OP_WAIT = 4'b0011;
    localparam logic [3:0] OP_READ = 4'b0101;
    localparam logic [3:0] OP_JNZ = 4'b0110;
    localparam logic [3:0] OP_HALT = 4'b0111;
    localparam logic [3:0] OP_TEST = 4'b1000;
    localparam logic [3:0] OP_SHIFT_TX  = 4'b1001;
    localparam logic [3:0] OP_LOAD_DATA = 4'b1010;
    localparam logic [3:0] OP_WRITE_BIT = 4'b1011;
    localparam logic [3:0] OP_SHIFT_WRITE = 4'b1100;
    // Decode current instruction
    assign opcode  = program_memory[pc][15:12];
    assign operand = program_memory[pc][7:0];

    // Program
    initial begin
        //program_memory[0] = {OP_LOAD_DATA, 4'b0000, 8'b10110010};
        //program_memory[1] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[2] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[3] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[4] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[5] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[6] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[7] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[8] = {OP_SHIFT_TX,  4'b0000, 8'h00};
        //program_memory[9] = {OP_HALT,     4'b0000, 8'h00};
	//program_memory[0] = {OP_LOAD_DATA,  4'b0000, 8'b10110010};
	//program_memory[1] = {OP_SHIFT_TX,   4'b0000, 8'h00};
	//program_memory[2] = {OP_WRITE_BIT,  4'b0000, 8'b00000001};
	//program_memory[3] = {OP_SHIFT_TX,   4'b0000, 8'h00};
	//program_memory[4] = {OP_WRITE_BIT,  4'b0000, 8'b00000001};
	//program_memory[5] = {OP_HALT,       4'b0000, 8'h00};
	program_memory[0] = {OP_LOAD_DATA,  4'b0000, 8'b10110010};
	program_memory[1] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[2] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
        program_memory[3] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[4] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[5] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[6] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[7] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	program_memory[8] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	//program_memory[7] = {OP_SHIFT_WRITE, 4'b0000, 8'b00000001};
	//program_memory[0] = {OP_TEST, 4'b0000, 8'b00000001};
	//program_memory[1] = {OP_JNZ, 4'b0000, 8'h03};
    	//program_memory[0] = {OP_READ, 4'b0000, 8'h00};
    	//program_memory[1] = {OP_JNZ,  4'b0000, 8'h03};
    	//program_memory[2] = {OP_JMP,  4'b0000, 8'h00};
    	//program_memory[3] = {OP_SET,  4'b0000, 8'h01};
	//program_memory[4] = {OP_HALT, 4'b0000, 8'h00};
    	//program_memory[0] = {OP_READ, 4'b0000, 8'h00};
    	//program_memory[1] = {OP_JMP,  4'b0000, 8'h00};
    	//program_memory[0] = {OP_SET,  4'b0000, 8'h01};
	//program_memory[1] = {OP_WAIT, 4'b0000, 8'h05};
	//program_memory[2] = {OP_CLR,  4'b0000, 8'h01};
	//program_memory[3] = {OP_JMP,  4'b0000, 8'h00};
        //program_memory[0] = {OP_SET, 4'b0000, 8'h01};
        //program_memory[1] = {OP_NOP, 4'b0000, 8'h00};
        //program_memory[2] = {OP_CLR, 4'b0000, 8'h01};
        //program_memory[3] = {OP_JMP, 4'b0000, 8'h00};
    end

    // Processor
    always_ff @(posedge clk) begin
        if (rst) begin
            pc   <= 8'h00;
            gpio <= 8'h00;
	    wait_counter <= 8'h00;
	    input_reg <= 8'h00;
	    data_reg <= 8'h00;
	    data_empty <= 1'b1;
	    data_bit <= 1'b0;
	    bits_remaining <= 4'd0;
        end
	else if (wait_counter != 0) begin
	    wait_counter <= wait_counter - 1;
	end
        else begin
            case (opcode)

                OP_NOP: begin
                    pc <= pc + 1;
                end

                OP_SET: begin
                    gpio <= gpio | operand;
                    pc   <= pc + 1;
                end

                OP_CLR: begin
                    gpio <= gpio & ~operand;
                    pc   <= pc + 1;
                end

                OP_JMP: begin
                    pc <= operand;
                end
		OP_WAIT: begin
                    wait_counter <= operand;
                    pc <= pc + 1;
                end
		OP_READ: begin
                    input_reg <= gpio_in;
                    pc <= pc + 1;
		end
		OP_JNZ: begin
                    if (input_reg != 8'h00) begin
                       pc <= operand;
                    end
                    else begin
                      pc <= pc + 1;
                    end
                end
		OP_HALT: begin
                    pc <= pc;
                end
		OP_TEST: begin
                    input_reg <= gpio_in & operand;
                    pc <= pc + 1;
                end
		OP_LOAD_DATA: begin
                    if (data_empty) begin
                       data_reg <= operand;
                       bits_remaining <= 4'd8;
                       data_empty <= 1'b0;
                       pc <= pc + 1;
                    end
                end

                OP_SHIFT_TX: begin
                   if (!data_empty) begin
                       data_bit <= data_reg[7];
                       data_reg <= data_reg << 1;

                       if (bits_remaining == 4'd1) begin
                           bits_remaining <= 4'd0;
                           data_empty <= 1'b1;
                       end
                       else begin
                           bits_remaining <= bits_remaining - 1;
                       end

                       pc <= pc + 1;
                   end
                end
                OP_WRITE_BIT: begin
                   if (data_bit)
                       gpio <= gpio | operand;
                   else
                       gpio <= gpio & ~operand;

                   pc <= pc + 1;
                end
		OP_SHIFT_WRITE: begin
                   if (!data_empty) begin
                       data_bit <= data_reg[7];
                       data_reg <= data_reg << 1;

                       if (bits_remaining == 4'd1) begin
                           bits_remaining <= 4'd0;
                           data_empty <= 1'b1;
                       end
                       else begin
                           bits_remaining <= bits_remaining - 1;
                       end

                       if (data_reg[7])
                           gpio <= gpio | operand;
                       else
                           gpio <= gpio & ~operand;

                      pc <= pc + 1;
                   end
                end
                default: begin
                    pc <= pc + 1;
                end

            endcase
        end
    end

endmodule
