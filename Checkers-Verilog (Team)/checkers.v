`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate
module checkers
 (
  CLOCK_50,      // On Board 50 MHz
  KEY,       // On Board Keys
  SW,
  HEX5,
  HEX4,
  HEX1,
  HEX0,
  PS2_DAT,
  PS2_CLK,
  // The ports below are for the VGA output.  Do not change.
  VGA_CLK,         // VGA Clock
  VGA_HS,       // VGA H_SYNC
  VGA_VS,       // VGA V_SYNC
  VGA_BLANK_N,      // VGA BLANK
  VGA_SYNC_N,      // VGA SYNC
  VGA_R,         // VGA Red[9:0]
  VGA_G,        // VGA Green[9:0]
  VGA_B,         // VGA Blue[9:0]
  LEDR
 );
 input   CLOCK_50;    // 50 MHz
 input    [3:0] KEY;
 input    [9:0] SW;

 inout PS2_DAT;
 inout PS2_CLK;

 wire keyboard_output_signal;
 wire [7:0] outputKeyboard;

 wire [2:0] dix;
 wire [2:0] diy;
 wire spacebar_enable;

 wire      [191:0] board;
 // Declare your inputs and outputs here
 // Do not change the following outputs
 output   VGA_CLK;       // VGA Clock
 output   VGA_HS;     // VGA H_SYNC
 output   VGA_VS;     // VGA V_SYNC
 output   VGA_BLANK_N;    // VGA BLANK
 output   VGA_SYNC_N;    // VGA SYNC
 output [7:0] VGA_R;       // VGA Red[7:0] Changed from 10 to 8-bit DAC
 output [7:0] VGA_G;      // VGA Green[7:0]
 output [7:0] VGA_B;       // VGA Blue[7:0]
 output [9:0] LEDR;
 wire resetn, go, reset, writeE;
 assign draw = !KEY[1];
 assign resetn = KEY[2];
 assign reset = !KEY[0];
 // Create the colour, x, y and writeEn wires that are inputs to the controller.
 wire [2:0] colour;
 wire [7:0] x;
 wire [6:0] y;

 wire start, player_sel, player_valid, player_won, win, choose, p1win;
 reg [2:0] pieces [0:7] [0:7];
 wire [2:0] highlightX;
 wire [2:0] highlightY;

 wire [3:0] p1scoree, p2scoree;

 
 output [6:0] HEX0, HEX1, HEX4, HEX5;
 
 PS2_Controller mainPS2(
	// Inputs
		.CLOCK_50(CLOCK_50),
		.reset(reset),

	// Bidirectionals
	   .PS2_CLK(PS2_CLK),   // PS2 Clock
 	   .PS2_DAT(PS2_DAT),	// PS2 Data

	// Outputs
		.received_data(outputKeyboard),
		.received_data_en(keyboard_output_signal)			// If 1 - new data has been received, this is what you want brendan ! 
      );
	
	 wire enable_output; 

 // Create an Instance of a VGA controller - there can be only one!
 // Define the number of colours as well as the initial background
 // image file (.MIF) for the controller.
 vga_adapter VGA(
   .resetn(resetn),
   .clock(CLOCK_50),
   .colour(colour),
   .x(x),
   .y(y),
   .plot(writeE),
   /* Signals for the DAC to drive the monitor. */
   .VGA_R(VGA_R),
   .VGA_G(VGA_G),
   .VGA_B(VGA_B),
   .VGA_HS(VGA_HS),
   .VGA_VS(VGA_VS),
   .VGA_BLANK(VGA_BLANK_N),
   .VGA_SYNC(VGA_SYNC_N),
   .VGA_CLK(VGA_CLK));
  defparam VGA.RESOLUTION = "160x120";
  defparam VGA.MONOCHROME = "FALSE";
  defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
  defparam VGA.BACKGROUND_IMAGE = "black.mif";

	wire [3:0] currstate;
	
	
	control c0(
	  .clk(CLOCK_50),
	  .resetn(resetn),
	  .go(go),
	  .start(start),
	  .check(check),
	  .draw(draw),
	  .player_sel(player_sel),
	  .player_valid(player_valid),
	  .player_won(player_won),
	  .win(win),
	  .player_choose(choose),
	  .currentState(currstate)
    );
	 
	 wire whoTurn; //  8 9 4 3
	 
	 assign LEDR[2:0] = 0;
	 assign LEDR[7:5] = 0;
	 assign LEDR[3] = whoTurn;
	 assign LEDR[4] = whoTurn;
	 assign LEDR[8] = !whoTurn;
	 assign LEDR[9] = !whoTurn;

  datapath data(
		.clk(CLOCK_50),
		.board(board),
		.x(dix),
		.y(diy),
		.start(start),
		.checkWin(check),
		.playerSel(player_sel),
		.playerValid(player_valid),
		.win(win),
		.highlightX(highlightX),
		.highlightY(highlightY),
		.p1scoreout(p1scoree),
		.p2scoreout(p2scoree),
		.whoturn(whoTurn)
    );

	 wire keyPressedDown;
	 
  drawBoard drawer(
   .clk(CLOCK_50),
   .colour(colour),
   .draw(draw),
   .writeE(writeE),
   .selX(dix),
   .selY(diy),
   .highlightX(highlightX),
   .highlightY(highlightY),
   .showHigh(choose),
   .X(x),
   .Y(y),
	.board(board),
   .win(win),
   .p1win(p1win),
	.keyDown(keyPressedDown || player_sel || player_valid)
  );
  
	position_selector_kybd kybd1(outputKeyboard,keyboard_output_signal,CLOCK_50, diy, dix, keyboard_output_signal, keyPressedDown, go); // this is the instantiation of the keyboard
	
	wire [3:0] p1ones;
	wire [3:0] p1tens;
	
	wire [3:0] p2ones;
	wire [3:0] p2tens;
	
	assign p1ones = 4'b0 + ((p1scoree > 9) ? p1scoree - 10 : p1scoree);
	assign p1tens = 4'b0 + (p1scoree > 9);
	
	assign p2ones = 4'b0 + ((p2scoree > 9) ? p2scoree - 10 : p2scoree);
	assign p2tens = 4'b0 + (p2scoree > 9);
	
	hex_decoder H5(
        .hex_digit(p2tens), 
        .segments(HEX5)
        );
	hex_decoder H4(
        .hex_digit(p2ones), 
        .segments(HEX4)
        );
	hex_decoder H1(
        .hex_digit(p1tens), 
        .segments(HEX1)
        );
	hex_decoder H0(
        .hex_digit(p1ones), 
        .segments(HEX0)
        );
  
endmodule


module datapath(clk, reset, board, x, y, start, checkWin, playerSel, playerValid, win, highlightX, highlightY, p1scoreout, p2scoreout, whoturn);
  output reg [191:0] board;
  output [2:0] highlightX, highlightY;
  output win;
  output whoturn;
  input [2:0] x, y;
  input reset, clk, checkWin, playerSel, playerValid, start;

  reg currentTurn = 0; // keep track of who's turn it is 0 = red turn 1 = black turn
  reg [191:0] initialBoard = 192'b001000001000001000001000000001000001000001000001001000001000001000001000000000000000000000000000000000000000000000000000000010000010000010000010010000010000010000010000000010000010000010000010;

  reg isValid;
  reg [2:0] current_spot;
  reg [2:0] future_spot;
  reg [2:0] delta_x, delta_y;
  reg [2:0] highX, highY;
  output [3:0] p1scoreout;
  output [3:0] p2scoreout;
  reg [3:0] p1score, p2score;

  assign p1scoreout = p1score;
  assign p2scoreout = p2score;
  assign highlightX = highX;
  assign highlightY = highY;
  assign whoturn = currentTurn;

  assign win = 0;//p1score == 12 || p2score == 12;

  always@(posedge clk) begin
	if(start) begin
    board = initialBoard;
    p1score = 0;
    p2score = 0;
  end
	if(checkWin) begin
		// **** insert code here
	end
	if(playerSel) begin
		highX = x;
		highY = y;		
	end
	if(playerValid) begin

		current_spot = board[highX*3+highY*24 +: 3]; //board[highX*3+highY*24:highX*3+highY*24+2];

		future_spot = board[x*3+y*24 +: 3];

		delta_x = highX > x ? highX-x : x-highX;
		delta_y = highY > y ? highY-y : y-highY;
		isValid = 1;
		

		if (currentTurn) begin  // player 1, top half of board and moving down blacks
			if((current_spot == 3'b001) || (current_spot == 3'b011))
				isValid = 1'd1;
			else
				isValid = 1'd0;
			if((y > highY) && (current_spot == 3'b001)) isValid = 1'b0; // highY must be greater to run
			if(isValid && (future_spot == 3'd0)) begin
				isValid = 1'b0;
				if((delta_x == 1) && (delta_y == 1)) begin // empty diagonal
					future_spot = current_spot;
					current_spot = 3'b0;
					isValid = 1'b1;
					if (y == 0) future_spot = 3'b011;
				end
			
				if((delta_x == 2) && (delta_y == 2)) begin // opponent piece in diagonal
					if(y < highY) begin 
					
						if ((x > highX) && ((board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b010) || (board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b100))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX+1)*3 + (highY-1)*24 +: 3] = 3'b0;
							p1score = p1score + 1;
							if (y == 0) future_spot = 3'b011;
						end
						
						if ((x < highX) && ((board[(highX-1)*3 + (highY-1)*24 +: 3] == 3'b010) || (board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b100))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX-1)*3 + (highY-1)*24 +: 3] = 3'b0;
							p1score = p1score + 1;
							if (y == 0) future_spot = 3'b011;
						end
						
					end else begin
					
						if ((x > highX) && ((board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b010) || (board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b100))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX+1)*3 + (highY+1)*24 +: 3] = 3'b0;
							p1score = p1score + 1;
							if (y == 0) future_spot = 3'b011;
						end
						
						if ((x < highX) && ((board[(highX-1)*3 + (highY+1)*24 +: 3] == 3'b010) || (board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b100))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX-1)*3 + (highY+1)*24 +: 3] = 3'b0;
							p1score = p1score + 1;
							if (y == 0) future_spot = 3'b011;
						end
					
					
					end
					
				end
			
			end
		end else begin // !currentTurn reds
			if((current_spot == 3'b010) || (current_spot == 3'b100))
				isValid = 1'd1;
			else
				isValid = 1'd0;
			if((y < highY) && (current_spot == 3'b010)) isValid = 1'b0;
			if(isValid && (future_spot == 3'd0)) begin
				isValid = 1'b0;
				if((delta_x == 1) && (delta_y == 1)) begin // empty diagonal
					future_spot = current_spot;
					current_spot = 3'b0;
					isValid = 1'b1;
					if (y == 7) future_spot = 3'b100;
				end
				
				if((delta_x == 2) && (delta_y == 2)) begin // opponent piece in diagonal
					if (y > highY) begin
					
						if ((x > highX) && ((board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b001) || (board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b011))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX+1)*3 + (highY+1)*24 +: 3] = 3'b0;
							p2score = p2score + 1;
							if (y == 7) future_spot = 3'b100;
						end
						
						if ((x < highX) && ((board[(highX-1)*3 + (highY+1)*24 +: 3] == 3'b001) || (board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b011))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX-1)*3 + (highY+1)*24 +: 3] = 3'b0;
							p2score = p2score + 1;
							if (y == 7) future_spot = 3'b100;
						end
					
					end else begin
					
					
						if ((x > highX) && ((board[(highX+1)*3 + (highY-1)*24 +: 3] == 3'b001) || (board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b011))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX+1)*3 + (highY-1)*24 +: 3] = 3'b0;
							p2score = p2score + 1;
							if (y == 7) future_spot = 3'b100;
						end
						
						if ((x < highX) && ((board[(highX-1)*3 + (highY-1)*24 +: 3] == 3'b001) || (board[(highX+1)*3 + (highY+1)*24 +: 3] == 3'b011))) begin // right diagonal
							isValid = 1;
							future_spot = current_spot;
							current_spot = 3'b0;
							board[(highX-1)*3 + (highY-1)*24 +: 3] = 3'b0;
							p2score = p2score + 1;
							if (y == 7) future_spot = 3'b100;
						end
					
					
					end
					
				end
				
				
			end
		end
		
     if (isValid) begin
       board[highX*3+highY*24 +: 3] = current_spot; //board[highX*3+highY*24:highX*3+highY*24+2];
		 currentTurn = ~currentTurn;
       board[x*3+y*24 +: 3] = future_spot;
     end //isValid
	  end
	end // always
endmodule

module control(
    input clk,
    input resetn,
    input go,
	 input win,
	 output [3:0] currentState,
	 output reg start, check, draw, player_sel, player_valid, player_won, player_choose
    );

    reg [3:0] current_state, next_state;
assign currentState = current_state;
	 // STATE CODE ASSIGNMENTS

    localparam  START_SCREEN	      = 5'd0,
					 CHECK_WIN                = 5'd1,
					 DRAW_BOARD	              = 5'd2,
					 PLAYER_SEL_OWN_PIECE	    = 5'd3,
					 PLAYER_SEL_VALID_POS     = 5'd4,
					 WINNING_SCREEN           = 5'd5,
					 PLAYER_SEL_PIECE_WAIT    = 5'd6,
					 PLAYER_SEL_VALID_WAIT    = 5'd7,
					 WAIT_1                   = 5'd8,
					 WAIT_2                   = 5'd9,
					 WAIT_3                   = 5'd10;


    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
              START_SCREEN:   		 next_state = go ? WAIT_3 : START_SCREEN;
              WAIT_3:           		 next_state = go ? WAIT_3 : CHECK_WIN;
				  CHECK_WIN:             next_state = win ? WINNING_SCREEN : PLAYER_SEL_PIECE_WAIT;
              PLAYER_SEL_PIECE_WAIT: next_state = go ? WAIT_1 : PLAYER_SEL_PIECE_WAIT;
              WAIT_1: 				    next_state = go ? WAIT_1 : PLAYER_SEL_OWN_PIECE;
				  PLAYER_SEL_OWN_PIECE:  next_state = PLAYER_SEL_VALID_WAIT;
              PLAYER_SEL_VALID_WAIT: next_state = go ? WAIT_2 : PLAYER_SEL_VALID_WAIT;
              WAIT_2: 					 next_state = go ? WAIT_2 : PLAYER_SEL_VALID_POS;
				  PLAYER_SEL_VALID_POS:  next_state = CHECK_WIN;
              WINNING_SCREEN: next_state = go ? START_SCREEN : WINNING_SCREEN;
            default:     next_state = START_SCREEN;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.

        start = 1'b0;
        check = 1'b0;
        draw = 1'b0;
        player_sel = 1'b0;
        player_valid = 1'b0;
		  player_won = 1'b0;
		  player_choose = 1'b0;

        case (current_state)
            START_SCREEN: begin
                start = 1'b1;
                end
            CHECK_WIN: begin
                check = 1'b1;
                end
            DRAW_BOARD: begin
					 draw = 1'b1;
                end
            PLAYER_SEL_OWN_PIECE: begin
                player_sel = 1'b1;
                end
				WAIT_2: begin
					 player_choose = 1'b1;
					 end
				PLAYER_SEL_VALID_WAIT: begin
					 player_choose = 1'b1;
					 end
				PLAYER_SEL_VALID_POS: begin
                player_valid = 1'b1;
					 end
			   WINNING_SCREEN:
		          player_won = 1'b1;
			endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= START_SCREEN;
        else
            current_state <= next_state;
    end // state_FFS

endmodule


module position_selector_kybd(keyboard_input, valid, slow_clock, data_in_X, data_in_Y, key_enable, keyPressed, spacebar_enable);

	reg [25:0] countdown = 0; //26'b01011111010111100000111111; 
 
	input [7:0] keyboard_input;  
	input valid, slow_clock; 
	output reg [2:0] data_in_X; 
	output reg [2:0] data_in_Y;
	output reg spacebar_enable;
	output keyPressed;
	
	assign keyPressed = countdown == 26'b00011111010111100000111111;
	
	reg [7:0] newKeyboardpress;
	input key_enable;
	
	reg keyEnableHeld = 0;
	reg keyClicked = 0;
	
	always@(posedge slow_clock)  begin
		spacebar_enable = 1'b0;
		keyClicked = 0;
		if (key_enable && !(keyEnableHeld)) begin
			keyClicked = 1;
			keyEnableHeld = 1;
		end
		if (!key_enable) keyEnableHeld = 0;
		if (countdown != 0) countdown = countdown - 1;
		if((!(newKeyboardpress == keyboard_input)) && (countdown == 0) && keyClicked) begin 
			newKeyboardpress = keyboard_input;
			if (keyboard_input == 8'h29) begin // spacebar 
				spacebar_enable = 1'b1;
				countdown = 26'b00011111010111100000111111;
			end else spacebar_enable = 0;
			if(keyboard_input == 8'h75) begin // UP Arrow key 
				if(data_in_X == 3'b0) begin
					data_in_X = data_in_X + 3'd7;
					countdown = 26'b00011111010111100000111111;
			//		spacebar_enable = 1'b0;
				end 
				else begin 
					data_in_X = data_in_X - 1'b1;
					countdown = 26'b00011111010111100000111111;
			//		spacebar_enable = 1'b0;
				end
			end 
			
			if(keyboard_input == 8'h6B) begin // LEFT Arrow key 
				if(data_in_Y == 3'b0) begin  
			     data_in_Y = data_in_Y + 3'd7;  
				  countdown = 26'b00011111010111100000111111;
			//	  spacebar_enable = 1'b0;
				end
				else begin  
				  data_in_Y = data_in_Y - 1'b1; 
				  countdown = 26'b00011111010111100000111111;
			//	  spacebar_enable = 1'b0;
				end  
			end
			
			if(keyboard_input == 8'h74) begin // RIGHT Arrow key 
				if(data_in_Y == 3'b111) begin  
					 data_in_Y = data_in_Y - 3'd7;
					 countdown = 26'b00011111010111100000111111;
			//		 spacebar_enable = 1'b0;
				end 
				else begin  
					 data_in_Y = data_in_Y + 1'b1; 
					 countdown = 26'b00011111010111100000111111;
			//		 spacebar_enable = 1'b0;
				end
			end 
			
			if(keyboard_input == 8'h72) begin // DOWN Arrow key 
				if(data_in_X == 3'b111) begin
					 data_in_X = data_in_X - 3'd7;
					 countdown = 26'b00011111010111100000111111;		 
			//		 spacebar_enable = 1'b0;
				end 
				else begin
					 data_in_X = data_in_X + 1'b1;
					 countdown = 26'b00011111010111100000111111;	 
			//		 spacebar_enable = 1'b0; 
				end 
			end  
		end 
	end 
	
endmodule

/*
module abs(
	input [2:0] a,
	input [2:0] b,
	output [2:0] res
	);

	wire [2:0] tmp;
	assign tmp = a-b;
	assign res = (~tmp[2:0])+3'h01;
endmodule
*/

		

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
 