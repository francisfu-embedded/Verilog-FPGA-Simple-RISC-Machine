module ALU(Ain,Bin,ALUop,out,Z); 

input [15:0] Ain, Bin; 
input [1:0] ALUop; 
output [15:0] out; 
output Z; // fill out the rest endmodule 

reg [15:0]storeout;

always @(*)begin
   case(ALUop)
     2'b00: storeout=Ain+Bin;
	 2'b01: storeout=Ain-Bin;
	 2'b10: storeout=Ain&Bin;
	 2'b11: storeout=~Bin;
	 default: storeout=16'bxxxxxxxxxxxxxxxx;
   endcase
end 
 assign out=storeout;
 assign Z=&(~storeout);
endmodule