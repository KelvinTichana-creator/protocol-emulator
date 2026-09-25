`timescale 1ns/1ps

module protocol_engine_tb;

    logic       clk;
    logic       rst;
    logic [7:0] gpio_in;
    logic [7:0] gpio;

    // Instantiate the protocol engine
    protocol_engine dut (
        .clk  (clk),
        .rst  (rst),
	.gpio_in (gpio_in),
        .gpio (gpio)
    );

    // Clock generation
    initial begin
        clk = 0;

        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
    	$dumpfile("protocol_engine.vcd");
	$dumpvars(0, tb);
	// Set external input
    	gpio_in = 8'b00000000;

    	// Start in reset
    	rst = 1;
    	#20;

    	// Release reset
    	rst = 0;

    	// Run the processor
    	#100;

    	// End simulation
        // Start in reset
        //rst = 1;

        //#20;

        // Release reset
        //rst = 0;

        // Run the processor
        //#100;

        // End simulation
        $finish;

    end

    // Display important signals
    initial begin
        $monitor(
    		"time=%0t rst=%b pc=%0d gpio=%b wait=%0d input=%b data=%b bit=%b remaining=%0d empty=%b",
    		$time,
    		rst,
    		dut.pc,
    		gpio,
    		dut.wait_counter,
    		dut.input_reg,
    		dut.data_reg,
    		dut.data_bit,
    		dut.bits_remaining,
    		dut.data_empty
               );
 end
endmodule
