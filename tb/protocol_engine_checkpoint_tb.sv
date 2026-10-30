`timescale 1ns/1ps

module protocol_engine_tb;

    logic clk;
    logic rst;
    logic [7:0] gpio_in;
    wire [7:0] gpio;

    localparam integer EXPECTED_FRAME_INTERVAL_NS = 530;

    integer expected_loops;
    integer frame_count;
    integer bit_index;
    integer expected_bit;

    time start_time;
    time previous_start_time;

    protocol_engine dut (
        .clk     (clk),
        .rst     (rst),
        .gpio_in (gpio_in),
        .gpio    (gpio)
    );

    // 10 ns clock period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Initialize and run the test
    initial begin
        rst = 1'b1;
        gpio_in = 8'h00;
        frame_count = 0;
        expected_loops = 0;
        previous_start_time = 0;

        // Read the expected frame count from the command line.
        if (!$value$plusargs("loops=%d", expected_loops))
            expected_loops = 0;

        if (expected_loops < 0 || expected_loops > 255)
            $fatal(1, "FAIL: loops must be between 0 and 255.");

        $display("Expected UART frames: %0d", expected_loops);

        // Allow program memory initialization to finish.
        #1;

        // Release reset at 20 ns.
        #19;
        rst = 1'b0;

        // Allow time for all expected frames to complete.
        #((expected_loops * EXPECTED_FRAME_INTERVAL_NS) + 300);

        if (frame_count != expected_loops) begin
            $fatal(1,
                "FAIL: Expected %0d frames, but observed %0d.",
                expected_loops, frame_count);
        end

        if (dut.loop_count !== 8'd0) begin
            $fatal(1,
                "FAIL: loop_count should be zero, but is %0d.",
                dut.loop_count);
        end

        if (dut.opcode !== 4'b0111) begin
            $fatal(1,
                "FAIL: Expected HALT, but opcode is %b at PC=%0d.",
                dut.opcode, dut.pc);
        end

        $display("----------------------------------------");
        $display("PASS: Test completed successfully.");
        $display("Expected frames: %0d", expected_loops);
        $display("Observed frames: %0d", frame_count);
        $display("Final PC: %0d", dut.pc);
        $display("----------------------------------------");

        $finish;
    end

    // Monitor UART frames and verify their data.
    // Expected logical byte: 0xB2, transmitted LSB-first.
    initial begin
        forever begin
            @(negedge gpio[0]);

            if (!rst) begin
                frame_count = frame_count + 1;

                $display(
                    "Frame %0d start detected at %0t",
                    frame_count, $time
                );

                if (frame_count > expected_loops) begin
                    $fatal(1,
                        "FAIL: Unexpected frame %0d detected at %0t.",
                        frame_count, $time);
                end

                start_time = $time;

                // Check the spacing between consecutive frames.
                if (frame_count > 1) begin
                    if ((start_time - previous_start_time)
                        != EXPECTED_FRAME_INTERVAL_NS) begin
                        $fatal(1,
                            "FAIL: Frame interval was %0t; expected %0d ns.",
                            start_time - previous_start_time,
                            EXPECTED_FRAME_INTERVAL_NS);
                    end
                end

                previous_start_time = start_time;

                // Check that the start bit is LOW.
                #25;
                if (gpio[0] !== 1'b0) begin
                    $fatal(1,
                        "FAIL: Start bit was not LOW in frame %0d.",
                        frame_count);
                end

                // Sample data bits at their centers.
                #50;

                for (bit_index = 0; bit_index < 8;
                     bit_index = bit_index + 1) begin

                    expected_bit = (8'hB2 >> bit_index) & 1;

                    if (gpio[0] !== expected_bit[0]) begin
                        $fatal(1,
                            "FAIL: Frame %0d, bit %0d: expected %0d, got %0b at %0t.",
                            frame_count,
                            bit_index,
                            expected_bit,
                            gpio[0],
                            $time);
                    end

                    $display(
                        "Frame %0d, bit %0d: %0d",
                        frame_count, bit_index, gpio[0]);

                    if (bit_index < 7)
                        #50;
                end

                // Check the stop bit.
                #50;

                if (gpio[0] !== 1'b1) begin
                    $fatal(1,
                        "FAIL: Stop bit was not HIGH in frame %0d at %0t.",
                        frame_count, $time);
                end

                $display("Frame %0d: PASS", frame_count);
            end
        end
    end

endmodule

