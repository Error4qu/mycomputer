module alu_tb;
logic [31:0] a,b,y;
logic [1:0] op;

alu dut(.a(a) , .b(b), .op(op), .y(y));

// [Claude] replaced the for-loop: each test sets a, b, op and checks a hand-written expected value
initial begin
	a = 32'd5; b = 32'd3; op = 2'b00; #1;
	$display("add:      y=%h %s", y, (y === 32'd8) ? "PASS" : "FAIL");

	a = 32'd3; b = 32'd5; op = 2'b01; #1;
	$display("sub:      y=%h %s", y, (y === 32'hFFFF_FFFE) ? "PASS" : "FAIL");

	a = 32'hFFFF_FFFF; b = 32'd1; op = 2'b00; #1;
	$display("add_wrap: y=%h %s", y, (y === 32'h0) ? "PASS" : "FAIL");

	a = 32'hF0F0_F0F0; b = 32'hFF00_FF00; op = 2'b10; #1;
	$display("and:      y=%h %s", y, (y === 32'hF000_F000) ? "PASS" : "FAIL");

	a = 32'hF0F0_F0F0; b = 32'h0F0F_0F0F; op = 2'b11; #1;
	$display("or:       y=%h %s", y, (y === 32'hFFFF_FFFF) ? "PASS" : "FAIL");

	$finish;
end
endmodule
