module regfile(data_in,writenum,write,readnum,clk,data_out); 
input [15:0] data_in; 
input [2:0] writenum, readnum; 
input write, clk; 
output [15:0] data_out; 

wire [7:0]first_decoder_out;
wire [7:0]select;
wire [7:0]enable;
wire [15:0]R0,R1,R2,R3,R4,R5,R6,R7;

assign enable={8{write}}&first_decoder_out;

decoder decoder1(writenum,first_decoder_out);
decoder decoder2(readnum,select);
register #(16)Reg0(clk,enable[0],data_in,R0);
register #(16)Reg1(clk,enable[1],data_in,R1);
register #(16)Reg2(clk,enable[2],data_in,R2);
register #(16)Reg3(clk,enable[3],data_in,R3);
register #(16)Reg4(clk,enable[4],data_in,R4);
register #(16)Reg5(clk,enable[5],data_in,R5);
register #(16)Reg6(clk,enable[6],data_in,R6);
register #(16)Reg7(clk,enable[7],data_in,R7);
multiplexer multiplexer1(R0,R1,R2,R3,R4,R5,R6,R7,select,data_out);

endmodule

//I used the code provided in the lab5 introduction ppt. Salute to Doctor Aamoodt!
module register(clk, en, in, out) ;
  parameter n = 16;  
  input clk, en ;
  input  [n-1:0] in ;
  output [n-1:0] out ;
  reg    [n-1:0] out ;
  wire   [n-1:0] next_out ;

  assign next_out = en ? in : out;

  always @(posedge clk)
    out = next_out;  
endmodule

module decoder(in,out);
   parameter n=3;
   parameter m=8;
   input [n-1:0]in;
   output [m-1:0]out;
   assign out=1<<in;
endmodule

module multiplexer(in0,in1,in2,in3,in4,in5,in6,in7,select,out);
parameter n=16;
  input [n-1:0]in0,in1,in2,in3,in4,in5,in6,in7;
  input [7:0]select;
  output [n-1:0]out;
  
  assign out=({n{select[0]}}&in0)|
             ({n{select[1]}}&in1)|
			 ({n{select[2]}}&in2)|
			 ({n{select[3]}}&in3)|
			 ({n{select[4]}}&in4)|
			 ({n{select[5]}}&in5)|
			 ({n{select[6]}}&in6)|
			 ({n{select[7]}}&in7);
  
endmodule
