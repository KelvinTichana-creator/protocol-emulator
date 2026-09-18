module protocol_engine (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] gpio
);

    // Program counter
    logic [7:0] pc;

    //timer register
    logic [7:0] wait_counter;

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

    // Decode current instruction
    assign opcode  = program_memory[pc][15:12];
    assign operand = program_memory[pc][7:0];

    // Program
    initial begin
    	program_memory[0] = {OP_SET,  4'b0000, 8'h01};
	program_memory[1] = {OP_WAIT, 4'b0000, 8'h05};
	program_memory[2] = {OP_CLR,  4'b0000, 8'h01};
	program_memory[3] = {OP_JMP,  4'b0000, 8'h00};
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

                default: begin
                    pc <= pc + 1;
                end

            endcase
        end
    end

endmodule
