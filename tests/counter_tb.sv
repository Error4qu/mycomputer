// [Claude] rewritten: one clock, one test sequence, testbench never drives 'count'
module counter_tb;
logic clk,en,rst;
logic [7:0] count;
counter dut(.clk(clk) , .en(en) , .rst(rst), .count(count));

// clock: toggles every 5 time units (one cycle = 10)
initial clk = 0;
always #5 clk = ~clk;

// waveform file for GTKWave
initial begin
	$dumpfile("counter.vcd");
	$dumpvars(0, counter_tb);
end

// the test: ONE initial block, steps run in order
initial begin
	// 1. reset
	rst = 1; en = 0;
	@(posedge clk); #1;
	$display("reset:         count=%0d %s", count, (count === 8'd0) ? "PASS" : "FAIL");

	// 2. count for 5 cycles
	rst = 0; en = 1;
	repeat (5) @(posedge clk); #1;
	$display("5 cycles en=1: count=%0d %s", count, (count === 8'd5) ? "PASS" : "FAIL");

	// 3. hold for 3 cycles
	en = 0;
	repeat (3) @(posedge clk); #1;
	$display("3 cycles en=0: count=%0d %s", count, (count === 8'd5) ? "PASS" : "FAIL");

	$finish;
end

endmodule
