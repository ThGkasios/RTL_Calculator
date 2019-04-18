// Themistoklis Gkasios
// Calculator module
module erg_calc(clk, reset, keyb_data, keyb_clk, disp_n1, disp_op, disp_n2, disp_eq, disp_r1, disp_r0);
// module I/O declaration
	//inout keyb_clk; //Keyboard clock
	input keyb_clk; // For simulation
	input clk, reset, keyb_data; //Inputs
	output [6:0] disp_n1, disp_op, disp_n2, disp_eq, disp_r1, disp_r0;// Display LEDs: n1, op, n2, eq, [r1,r0]
	wire clk, reset, keyb_data, keyb_clk;
	reg [6:0] disp_n1, disp_op, disp_n2, disp_eq, disp_r1, disp_r0;
//End of module I/O declaration

//Resource declaration	
	reg addition, err;
	reg [3:0] num1, num2;
	reg [2:0] curr_state, next_state;
	wire [4:0] res;
	wire [3:0] disp_res1, disp_res0;	
	reg [6:0] LEDv [14:0];
	//FSM State parameters
	parameter INIT_ST = 3'b000;// Reset calculator
	parameter WAIT_N1 = 3'b001;// Wait for first number
	parameter WAIT_OP = 3'b010;// Wait for operator (+/-)
	parameter WAIT_N2 = 3'b011;// Wait for second number
	parameter WAIT_EQ = 3'b100;// Wait for 'equals'
	parameter NEXT_ST = 3'b101;// Regulate state stream	
//End of resource declaration

//Keyboard data interpreter
	reg [5:0] keyb_clk_sample;
	reg [10:0] keyb_data_reg;
	reg [3:0] dec_key;
	//assign keyb_clk = (!keyb_data_reg[0])?1'b0:1'bz;
	always @ (posedge clk or posedge reset) //keyboard signal detection
		if(reset) keyb_clk_sample <= 6'b000000;
		else keyb_clk_sample <= {keyb_clk, keyb_clk_sample[5:1]};
	always @ (posedge clk or posedge reset) begin //keyboard data reading
		if(reset) keyb_data_reg <= 11'b11111111111;
		else if(!keyb_data_reg[0]) keyb_data_reg <= 11'b11111111111;
		else if(keyb_clk_sample == 6'b000111) keyb_data_reg <= {keyb_data, keyb_data_reg[10:1]};
	end
	//keyboard data extraction and interpretation
	//Dec_key|Meaning
	// 0     |0 (row or numpad)
	// 1     |1 (row or numpad)
	// 2     |2 (row or numpad)
	// 3     |3 (row or numpad)
	// 4     |4 (row or numpad)
	// 5     |5 (row or numpad)
	// 6     |6 (row or numpad)
	// 7     |7 (row or numpad)
	// 8     |8 (row or numpad)
	// 9     |9 (row or numpad)
	//10     |+ (reduced, numpad)
	//11     |- (row or numpad)
	//12     |= (also triggered with central enter)
	//13     |unused
	//14     |Initial state upon reset
	//15     |Error, activates on unrecognisable inputs
	always @ (posedge clk or posedge reset) begin
		if(reset) dec_key <= 4'd14;
		else if(!keyb_data_reg[0]) begin
			case(keyb_data_reg[8:1]) 
				8'h45: dec_key <= 4'd0;
				8'h70: dec_key <= 4'd0;
				8'h16: dec_key <= 4'd1;
				8'h69: dec_key <= 4'd1;
				8'h1e: dec_key <= 4'd2;
				8'h72: dec_key <= 4'd2;
				8'h26: dec_key <= 4'd3;
				8'h7a: dec_key <= 4'd3;
				8'h25: dec_key <= 4'd4;
				8'h6b: dec_key <= 4'd4;
				8'h2e: dec_key <= 4'd5;
				8'h73: dec_key <= 4'd5;
				8'h36: dec_key <= 4'd6;
				8'h74: dec_key <= 4'd6;
				8'h3d: dec_key <= 4'd7;
				8'h6c: dec_key <= 4'd7;
				8'h3e: dec_key <= 4'd8;
				8'h75: dec_key <= 4'd8;
				8'h46: dec_key <= 4'd9;
				8'h7d: dec_key <= 4'd9;
				8'h79: dec_key <= 4'd10;
				8'h4e: dec_key <= 4'd11;
				8'h7b: dec_key <= 4'd11;
				8'h55: dec_key <= 4'd12;
				8'h5a: dec_key <= 4'd12;
				default: dec_key <= 4'd15;
			endcase
		end
	end
//End of keyboard data interpreter

//Finite State Machine
	assign res = {1'd0,num1} + ({1'd0,num2} ^ {5{addition}}) + {4'd0,addition}; //Calculate result from operands and operator
	assign disp_res1 = (res < 5'd10)? 4'd13:(res > 5'd18)?4'd11:4'd1;
	assign disp_res0 = ((res < 5'd19)?res[3:0]:-res[3:0])%10;
	always @ (posedge clk or posedge reset) begin
		if (reset) begin //initialize resources and display
			addition <= 1'b0;
			err <= 1'b0;
			num1 <= 4'd0;
			num2 <= 4'd0;
			curr_state <= WAIT_N1;
			next_state <= WAIT_N1;
			disp_n1 <= LEDv[13];
			disp_op <= LEDv[13];
			disp_n2 <= LEDv[13];
			disp_eq <= LEDv[13];
			disp_r1 <= LEDv[13];
			disp_r0 <= LEDv[13];
		end
		else begin
			case (next_state)
				INIT_ST: begin//Initialize display on restart, and wait for next number key press
					if (dec_key > 4'd9) err <= 1'b1;
					else begin
						num1 <= 4'd0;
						num2 <= 4'd0;
						addition <= 1'b0;
						disp_n1 <= LEDv[13];
						disp_op <= LEDv[13];
						disp_n2 <= LEDv[13];
						disp_eq <= LEDv[13];
						disp_r1 <= LEDv[13];
						disp_r0 <= LEDv[13];
						err <= 1'b0;
					end
					curr_state <= next_state;
					next_state <= NEXT_ST;
				end
				WAIT_N1: begin
					if (dec_key == 4'd15) begin
						disp_n1 <= LEDv[14];		//Error message on unrecognisable input
						err <= 1'b1;
					end
					else if (dec_key > 4'd9) begin
						disp_n1 <= LEDv[13];		//Empty message on recognisable invalid input
						err <= 1'b1;
					end
					else begin
						disp_n1 <= LEDv[dec_key];	//Display number on recognisable valid input
						num1 <= dec_key;
						err <= 1'b0;
					end
					
					curr_state <= next_state;
					next_state <= NEXT_ST;
				end
				WAIT_OP: begin
					if (dec_key == 4'd15) begin		//Display error on invalid input 
						disp_op <= LEDv[14];
						err <= 1'b1;
					end
					if (dec_key == 4'd10) begin
						disp_op <= LEDv[10];		//Display addition operator
						addition <= 1'b0;
						err <= 1'b0;
					end
					else if (dec_key == 4'd11) begin
						disp_op <= LEDv[11];		//Display subtraction operator
						addition <= 1'b1;
						err <= 1'b0;
					end
					else begin
						disp_op <= LEDv[13];	//Display empty message on recognisable invalid input
						err <= 1'b1;
					end
					curr_state <= next_state;
					next_state <= NEXT_ST;
				end
				WAIT_N2: begin
					if (dec_key == 4'd15) begin
						disp_n2 <= LEDv[14];		//Error message on unrecognisable input
						err <= 1'b1;
					end
					else if (dec_key > 4'd9) begin
						disp_n2 <= LEDv[13];		//Empty message on recognisable invalid input
						err <= 1'b1;
					end
					else begin
						disp_n2 <= LEDv[dec_key];	//Display number on recognisable valid input
						num2 <= dec_key;
						err <= 1'b0;
					end
					curr_state <= next_state;
					next_state <= NEXT_ST;	
				end
				WAIT_EQ: begin
					if (dec_key == 4'd12) begin		//Display equal sign and result on equal press
						disp_eq <= LEDv[12];
						disp_r1 <= LEDv[disp_res1];
						disp_r0 <= LEDv[disp_res0];
						err <= 1'b0;
					end
					else begin						//Empty message on any other input
						disp_eq <= LEDv[13];
						err <= 1'b1;
					end
					curr_state <= next_state;
					next_state <= NEXT_ST;
				end
				NEXT_ST:
					if (err)
						next_state <= curr_state;			
					else if (curr_state == INIT_ST)
						next_state <= WAIT_N1;
					else if (curr_state == WAIT_N1)
						next_state <= WAIT_OP;
					else if (curr_state == WAIT_OP)
						next_state <= WAIT_N2;
					else if (curr_state == WAIT_N2)
						next_state <= WAIT_EQ;
					else if (curr_state == WAIT_EQ)
						next_state <= INIT_ST;
				default: begin //losing track of current state causes a reset
						//initialize resources and display
						addition <= 1'b0;
						err <= 1'b0;
						num1 <= 4'd0;
						num2 <= 4'd0;
						curr_state <= INIT_ST;
						next_state <= WAIT_N1;
						disp_n1 <= LEDv[13];
						disp_op <= LEDv[13];
						disp_n2 <= LEDv[13];
						disp_eq <= LEDv[13];
						disp_r1 <= LEDv[13];
						disp_r0 <= LEDv[13];
					end
			endcase
		end
	end
//End of Finite State Machine

//Displayable values register
	always @ (posedge clk or posedge reset)
		if (reset) begin
			LEDv[0] <= 7'b1000000;	//0
			LEDv[1] <= 7'b1111001;	//1
			LEDv[2] <= 7'b0100100;	//2
			LEDv[3] <= 7'b0110000;	//3
			LEDv[4] <= 7'b0011001;	//4
			LEDv[5] <= 7'b0010010;	//5
			LEDv[6] <= 7'b0000010;	//6
			LEDv[7] <= 7'b1111000;	//7
			LEDv[8] <= 7'b0000000;	//8
			LEDv[9] <= 7'b0010000;	//9
			LEDv[10] <= 7'b0111001;	//+(reduced)
			LEDv[11] <= 7'b0111111;	//-
			LEDv[12] <= 7'b0110111;	//=
			LEDv[13] <= 7'b1111111;	//Empty
			LEDv[14] <= 7'b0000110;	//E
		end
endmodule