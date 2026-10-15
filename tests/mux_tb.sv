module mux_tb;
logic a,b,s,y;

mux dut (.a(a) , .b(b) , .s(s) , .y(y) );

initial begin
	for(int i=0;i<8;i++)begin
		{s,a,b} = 3'(i);
		#1
		$display("s = %b , a = %b, b = %b , res = %s" , s,a,b, y ==(s?b:a) ? "pass" : "fail");
	end
	$finish;
end
endmodule


