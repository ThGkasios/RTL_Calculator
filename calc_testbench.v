// Themistoklis Gkasios
// Calculator module test bench

module sim;

reg clk, reset, kclk, kdata;
wire [6:0] disp_n1, disp_op, disp_n2, disp_eq, disp_r1, disp_r0;
reg[49:0] data;
reg[5:0] dpointer;
erg_calc Calc(clk, reset, kdata, kclk, disp_n1, disp_op, disp_n2, disp_eq, disp_r1, disp_r0);


initial begin
	reset = 1'b0;
	#1 reset = 1'b1;
	clk = 1'b0;	
	kclk = 1'b0;
	data = 50'b11111100110100001010011110010011010001101010101011;//trash,1,+,1,=
	dpointer = 6'd49;//starts from data MSB
	kdata = 1'b0;
	#1 reset = 1'b0;
end

always @(posedge clk) kdata <= data[dpointer];
always #1 clk <= ~clk;
always @(posedge clk) #5 kclk <= ~kclk;
always @ (posedge kclk) begin
	if(dpointer>0)
		dpointer <= dpointer - 1;
	else
		dpointer <= 6'd49;
end
endmodule