module mem_tb;
logic [31:0] adress,wd,read,expected;
logic clk,we;
initial clk = 1'b1;
always #5 clk = ~clk;
mem dut(.adress(adress) , .wd(wd) , .read(read) , .clk(clk) , .we(we) ); 
initial begin
	we = 0;
	adress = 32'h80000000;
	expected = 32'h00000297;
	if(read == expected)begin
		$display("pass");
	end
	else begin
		$display("fail");
	end
	for(int i=0;i<1024;i++)begin
		we = 1'b1;adress=32'(i*4);
		wd = 32'(i*i);
		@(posedge clk);#1;
	end
	we = 0;
	for(int i=0;i<1024;i++)begin
		adress=32'(i*4);
		expected = 32'(i*i);
		#1;
		if(read===expected)begin
			$display("pass");
		end
		else begin
			$display("failing at %d and the expected val %h and res is %h" , adress , expected , read);
		end
	end
$finish;
end
endmodule

	
