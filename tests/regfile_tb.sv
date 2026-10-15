module regfile_tb;
logic [4:0] rd ,rs1,rs2;
logic [31:0] rd1 , rd2 , wd;
logic clk,we;
logic [31:0] exp1 , exp2;

regfile dut(.clk(clk) , .we(we) , .rd(rd) , .rs1(rs1) , .rs2(rs2) , .wd(wd) , .rd1(rd1) , .rd2(rd2));	// [Claude] connected wd, rd1, rd2

// [Claude] added clock
initial clk = 0;
always #5 clk = ~clk;

initial begin
	for(int i = 1; i < 32; i++)begin
		we = 1; wd = 32'(i+1);rd = 5'(i);@(posedge clk)#1;
	end
	
	for(int i = 0; i < 32; i++)begin
		we = 0;rs1 = 5'(i); rs2 = 5'(31-i);#1; 
		exp1= i==0 ? 0:32'(i+1);
		exp2= i==31 ? 0:32'(32-i);
		if(rd1===exp1 && rd2===exp2)begin
			$display("PASS");
		end
		else begin
			$display("FAIL");
		end

	end

$finish;			
end
endmodule
