`define MWRITE 2'b01
`define MREAD 2'b10
`define MNONE 2'b00

module lab8_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50); 
input [3:0] KEY;
input [9:0] SW;
input CLOCK_50;
output [9:0] LEDR;
output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
wire N,V,Z;
wire w;
wire [1:0]mem_cmd;
wire [8:0]mem_addr;
wire [15:0]read_data;
wire [15:0]write_data;
wire cmp1out,cmp2out,cmp3out,write,msel,trien;
wire [15:0] dout;
wire over;
reg enable1,enable2;
assign HEX5[0] = ~Z;
assign HEX5[6] = ~N;
assign HEX5[3] = ~V;
sseg H0(write_data[3:0],   HEX0);
sseg H1(write_data[7:4],   HEX1);
sseg H2(write_data[11:8],  HEX2);
sseg H3(write_data[15:12], HEX3);
assign HEX4 = 7'b1111111;
assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
assign LEDR[8] = over;
assign LEDR[9] = w;

cpu CPU(CLOCK_50,(~KEY[1]),read_data,write_data,N,V,Z,w,mem_cmd,mem_addr,over);
RAM MEM(CLOCK_50,mem_addr[7:0],mem_addr[7:0],write,write_data,dout);
comparator #(2)cmp1(`MWRITE,mem_cmd,cmp1out);
comparator #(2)cmp2(`MREAD,mem_cmd,cmp2out);
comparator cmp3(1'b0,mem_addr[8],msel);
assign write=cmp1out&msel;
assign trien=cmp2out&msel;
tristate #(16)triu1(trien,dout,read_data);
tristate #(16)triu2 (enable1,{8'b0,SW[7:0]},read_data);
register #(8)ledreg (CLOCK_50,enable2,write_data[7:0],LEDR[7:0]);
//dettermine if the requirements are met for tri state enable
always@(*)begin
  if(mem_addr=='d84&&mem_cmd==`MREAD)
     enable1=1;
  else
     enable1=0;
end
//dettermine if the requirements are met for register load
always@(*)begin
  if(mem_addr=='d88&&mem_cmd==`MWRITE)
     enable2=1;
  else
     enable2=0;
end

endmodule


module comparator (ain, bin, out);
parameter n=1;
input [n-1:0]ain,bin;
output out;
assign out=(ain==bin);
endmodule

module tristate(en,in,out);
parameter n=16;
input en;
input [n-1:0]in;
output [n-1:0]out;
assign out=en?in:16'bz;
endmodule

// The sseg module below can be used to display the value of datpath_out on
// the hex LEDS the input is a 4-bit value representing numbers between 0 and
// 15 the output is a 7-bit value that will print a hexadecimal digit.  You
// may want to look at the code in Figure 7.20 and 7.21 in Dally but note this
// code will not work with the DE1-SoC because the order of segments used in
// the book is not the same as on the DE1-SoC (see comments below).

module sseg(in,segs);
  input [3:0] in;
  output [6:0] segs;

  // NOTE: The code for sseg below is not complete: You can use your code from
  // Lab4 to fill this in or code from someone else's Lab4.  
  //
  // IMPORTANT:  If you *do* use someone else's Lab4 code for the seven
  // segment display you *need* to state the following three things in
  // a file README.txt that you submit with handin along with this code: 
  //
  //   1.  First and last name of student providing code
  //   2.  Student number of student providing code
  //   3.  Date and time that student provided you their code
  //
  // You must also (obviously!) have the other student's permission to use
  // their code.
  //
  // To do otherwise is considered plagiarism.
  //
  // One bit per segment. On the DE1-SoC a HEX segment is illuminated when
  // the input bit is 0. Bits 6543210 correspond to:
  //
  //    0000
  //   5    1
  //   5    1
  //    6666
  //   4    2
  //   4    2
  //    3333
  //
  // Decimal value | Hexadecimal symbol to render on (one) HEX display
  //             0 | 0
  //             1 | 1
  //             2 | 2
  //             3 | 3
  //             4 | 4
  //             5 | 5
  //             6 | 6
  //             7 | 7
  //             8 | 8
  //             9 | 9
  //            10 | A
  //            11 | b
  //            12 | C
  //            13 | d
  //            14 | E
  //            15 | F

`define Seven 7'b1111000
`define Zero  7'b1000000
`define Three 7'b0110000
`define Two   7'b0100100
`define Five  7'b0010010
`define Eight 7'b0000000
`define One   7'b1001111
`define Four  7'b0011001
`define Six   7'b1111101
`define Nine  7'b0010000
`define A     7'b0001000
`define B     7'b0000011
`define C     7'b1000110
`define D     7'b0100001
`define E     7'b0000110
`define F     7'b0001110
reg [6:0] segs;
always@(*)begin
  case(in)
  4'b0000:segs=`Zero;
  4'b0001:segs=`One;
  4'b0010:segs=`Two;
  4'b0011:segs=`Three;
  4'b0100:segs=`Four;
  4'b0101:segs=`Five;
  4'b0110:segs=`Six;
  4'b0111:segs=`Seven;
  4'b1000:segs=`Eight;
  4'b1001:segs=`Nine;
  4'b1010:segs=`A;
  4'b1011:segs=`B;
  4'b1100:segs=`C;
  4'b1101:segs=`D;
  4'b1110:segs=`E;
  4'b1111:segs=`F;
  default:segs=7'bxxxxxxx;
  endcase
end

endmodule

