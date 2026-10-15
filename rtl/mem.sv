module mem(
	/* verilator lint_off UNUSEDSIGNAL */
	input logic [31:0] adress,
	/* verilator lint_on UNUSEDSIGNAL */
	input logic [31:0] wd,
	output logic [31:0] read,
	input logic clk,
	input logic we
	);
	logic [31:0] memory[1024];
	initial $readmemh("/home/madhav/mycomp/build/first.hex", memory);

	always_ff@(posedge clk)begin
		if(we)begin
			memory[adress[11:2]] <= wd;
		end
	end
	assign read = memory[adress[11:2]];
endmodule
	
