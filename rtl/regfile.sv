module regfile(
	input logic [4:0] rd ,rs1,rs2 ,
	input logic [31:0] wd ,		// [Claude] wd is 32-bit data
	input logic clk,we,
	output logic [31:0] rd1 , rd2
	);

	logic [31:0] regs [32];		// [Claude] restored: the 32 registers

	always_ff@(posedge clk)begin
		if(we && rd!=5'd0)begin
			regs[rd]<=wd;
			regs[rd]<=32'hDEAD;
		end
	end
		assign rd2 = (rs2!=5'd0) ? regs[rs2]:32'd0;
		assign rd1 = (rs1!=5'd0) ? regs[rs1]:32'd0;
	endmodule
