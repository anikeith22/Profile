module drawBoard(colour, clk, draw, writeE, selX, selY, highlightX, highlightY, showHigh, X, Y, board, keyDown, win, p1win);
 input clk, draw, showHigh, keyDown, win, p1win;
 output reg writeE;
 output reg [2:0] colour;
 input [191:0] board;
 input [2:0] selX;
 input [2:0] selY;
 input [2:0] highlightX;
 input [2:0] highlightY;
 reg colourState, selRow;
 output [7:0] X; // from  0 - 120, intervals at  0, 15, 30, 45, 60, 75, 90, 105, 120
 output [6:0] Y; // from  0 - 120, intervals at  0, 15, 30, 45, 60, 75, 90, 105, 120

 reg [7:0] x;
 reg [6:0] y;
 reg drawing = 0;
 reg drawPieces = 0;
 reg drawingPieces = 0;
 reg [4:0] subX;
 reg [4:0] subY;

 assign X = x + 20 + subX;
 assign Y = y - (x < 15) + subY + (x < 14 && subX != 0);

 reg keyPressed = 1;

 always@(posedge clk) begin
  if (keyDown) keyPressed = 1;
  if (!drawing && !drawingPieces && keyPressed) begin
   keyPressed = 0;
   subX = 0;
   subY = 0;
   drawing = 1;
   x = -1;
   y = 0;
   colourState = 0;
   writeE = 1;
   selRow = (selY == 0);
  end
  if (drawing) begin
   if (((x+1) % 15) == 0) begin
    if (colourState) colour = 3'b110;
    else colour = 3'b111;
    colourState = ~colourState;
    if ((((x+1) == (selX * 15)) || selRow) || (x == 119 && selX == 0))
     colour = 3'b001; // selected row/col colour
    if (((x+1) == (highlightX *15) || (x == 119 && highlightX == 0)) && ((y+1) > highlightY*15) && (y < (highlightY+1)*15) && showHigh)
     colour = 3'b010;
   end
   x = x + 1;
   if (x == 120) begin
    x = 0;
    y = y + 1;
    if ((y % 15) == 0) begin
     colourState = ~colourState;
     if (selRow) selRow = 0;
     else if (y == (selY * 15)) selRow = 1; // highlight the row selected by selY
    end
    if (y == 120) begin
     drawing = 0;
     drawPieces = 1;
     drawingPieces = 0;
    end
   end
  end // drawing
  if (drawPieces) begin
   x = 0;
   y = 0;
   writeE = 0;
   drawingPieces = 1;
   drawPieces = 0;
   subX = 4;
   subY = 1;
  end
  if (drawingPieces) begin
   if (board[((x/5)+(y/5)*8) +: 3] != 3'b000) begin // ((x/15)*3+(y/15)*24) : ((x/15)*3+(y/15)*24+2)
	 writeE = 1;
    colour = 3'b100;
    if ((board[((x/5)+(y/5)*8) +: 2] == 3'b001) || (board[((x/5)+(y/5)*8) +: 2] == 3'b011))
		colour = 3'b000;
	 if (((board[((x/5)+(y/5)*8) +: 2] == 3'b011) || (board[((x/5)+(y/5)*8) +: 3] == 3'b100)) && subY > 6)
		colour = 3'b101;
    subX = subX + 1;
    if (subX == 9 && subY == 1) begin
     subX = 3;
     subY = 2;
    end
    if (subX == 11 && subY == 2) begin
     subX = 2;
     subY = 3;
    end
    if (subX == 12 && subY == 3) begin
     subX = 2;
     subY = 4;
    end
    if (subX == 12 && subY == 4) begin
     subX = 1;
     subY = 5;
    end
    if (subX == 13 && subY == 5) begin
     subX = 1;
     subY = 6;
    end
    if (subX == 13 && subY == 6) begin
     subX = 1;
     subY = 7;
	  
    end
    if (subX == 13 && subY == 7) begin
     subX = 1;
     subY = 8;
    end
    if (subX == 13 && subY == 8) begin
     subX = 1;
     subY = 9;
    end
    if (subX == 13 && subY == 9) begin
     subX = 2;
     subY = 10;
    end
    if (subX == 12 && subY == 10) begin
     subX = 2;
     subY = 11;
    end
    if (subX == 12 && subY == 11) begin
     subX = 3;
     subY = 12;
    end
    if (subX == 11 && subY == 12) begin
     subX = 5;
     subY = 13;
    end
    if (subX == 9 && subY == 13) begin
     subX = 4;
     subY = 1; //Restart
	  writeE = 0;
     x = x + 15;
     if (x == 120) begin
      y = y + 15;
		x = 0;
      if (y == 120) drawingPieces = 0;
     end
    end
   end // board != 000
   else begin
    x = x + 15;
    if (x == 120) begin
	  x = 0;
     y = y + 15;
     if (y == 120) drawingPieces = 0;
    end
   end
  end //drawingPieces
 end // always block
endmodule
