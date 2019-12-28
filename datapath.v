
module datapath(clk,readnum,vsel,loada,loadb,shift,asel,bsel,ALUop,loadc,loads,writenum,write,sximm8,sximm5,PC,mdata,sximmsel,Z_out,V_out,N_out,datapath_out);
input clk,loada,loadb,asel,bsel,loadc,loads,write;
input [3:0]vsel;
input [2:0]readnum,writenum;
input [1:0]shift,ALUop;
input [15:0] mdata,sximm8,sximm5; 
input [7:0]  PC;

input sximmsel;
output [15:0]datapath_out;
output Z_out,N_out,V_out;

wire [15:0] stalewire2=sximmsel?sximm8:sximm5;
wire [15:0]regfile_out;
wire [15:0] data_in,data_out,Aregout,Bregout,shifter_out,stalewire1,Ain,Bin,alu_out,feedback;
wire alu_z;
wire det=(ALUop==2'b01)?~Bin[15]:Bin[15];
wire [15:0] combinedPC={8'b00000000,PC};
wire overflow=(Ain[15]~^det)&(alu_out[15]^Ain[15]);
wire [2:0]stat={alu_z,overflow,alu_out[15]};
assign stalewire1=16'b0;
assign feedback=datapath_out;
assign data_out=vsel[2]?data_in:regfile_out;//changes the input pattern by putting data directly into dataout not through registers.


fourInputMulti mult1(mdata,sximm8,combinedPC,feedback,vsel,data_in);
regfile REGFILE(data_in,writenum,write,readnum,clk,regfile_out);
register A(clk,loada,data_out,Aregout);
register B(clk,loadb,data_out,Bregout);
shifter U1(Bregout,shift,shifter_out);
twoInputMulti mult2(stalewire1,Aregout,asel,Ain);
twoInputMulti mult3(stalewire2,shifter_out,bsel,Bin);
ALU U2(Ain,Bin,ALUop,alu_out,alu_z);
register C(clk,loadc,alu_out,datapath_out);
register #(3)reg4(clk,loads,stat,{Z_out,V_out,N_out});
endmodule

module fourInputMulti(ain,bin,cin,din,select,out);
 input [15:0]ain,bin,cin,din;
 input [3:0]select;
 output [15:0] out;
 assign out=({16{select[0]}}&ain)|
({16{select[1]}}&bin)|
({16{select[2]}}&cin)|
({16{select[3]}}&din);

endmodule

module twoInputMulti(ain,bin,select,out);
 input [15:0]ain,bin;
 input select;
 output [15:0] out;

 assign out=select?ain:bin;

endmodule


