module shifter(in,shift,sout); 
input [15:0] in; 
input [1:0] shift; 
output [15:0] sout;
reg[15:0] storeout;
always@(*)begin
   case(shift)
   2'b00: storeout=in;
   2'b01: storeout=in<<1;
   2'b10: storeout=in>>1;
   2'b11: begin storeout=in>>1; storeout[15]=1'b1; end
   default: storeout=16'bxxxxxxxxxxxxxxxx;
   endcase
   end

assign sout = storeout;
endmodule