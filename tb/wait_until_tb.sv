`timescale 1ns/1ps

module wait_until_tb;

    logic clk;
    logic rst;
    logic [7:0] gpio_in;
    logic [7:0] gpio;

    integer errors;

    // Instantiate the protocol emulator.
    protocol_engine dut (
        .clk(clk),
        .rst(rst),
        .gpio_in(gpio_in),
        .gpio(gpio)
    );

    // 10 ns clock period.
    always #5 clk = ~clk;

    initial begin
        clk     = 1'b0;
        rst     = 1'b1;
        gpio_in = 8'h00;
        errors  = 0;

        // Allow the RTL's initial program assignments to complete.
        #1;

        // Test program:
        //
        // Address 0: Wait until GPIO input 2 is HIGH.
        // Address 1: Set GPIO output 0 HIGH.
        // Address 2: Halt.

        dut.program_memory[0] = 16'h000A;
        dut.program_memory[1] = 16'h1001;
        dut.program_memory[2] = 16'h7000;

        // Keep reset active for two rising clock edges.
        repeat (2) @(posedge clk);

        // Release reset away from the active clock edge.
        @(negedge clk);
        rst = 1'b0;

        // Allow the first instruction to execute.
        @(negedge clk);
        #1;

        // Input pin 2 is LOW. The processor must remain at PC 0.
        if (dut.pc !== 8'd0) begin
            $display("FAIL: PC should remain at 0 while input 2 is LOW.");
            $display("      Actual PC = %0d", dut.pc);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Processor waits while input 2 is LOW.");
        end

        // Confirm that the output has not yet been set.
        if (gpio[0] !== 1'b0) begin
            $display("FAIL: GPIO output 0 changed before the input matched.");
            errors = errors + 1;
        end

        // Drive input pin 2 HIGH.
        gpio_in[2] = 1'b1;

        // Wait for the processor to detect the matching input level.
        @(negedge clk);
        #1;

        if (dut.pc !== 8'd1) begin
            $display("FAIL: PC should advance to 1 when input 2 becomes HIGH.");
            $display("      Actual PC = %0d", dut.pc);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Processor advances when input 2 becomes HIGH.");
        end

        // Allow the SET instruction to execute.
        @(negedge clk);
        #1;

        if (gpio[0] !== 1'b1) begin
            $display("FAIL: SET instruction did not set GPIO output 0.");
            $display("      Actual GPIO = %08b", gpio);
            errors = errors + 1;
        end
        else begin
            $display("PASS: The instruction after WAIT_UNTIL executes.");
        end

        // Report the result.
        if (errors == 0) begin
            $display("");
            $display("ALL WAIT_UNTIL TESTS PASSED");
        end
        else begin
            $display("");
            $display("WAIT_UNTIL TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule
