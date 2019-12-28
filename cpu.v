`define MWRITE 2'b01
`define MREAD 2'b10
`define MNONE 2'b00

module cpu(clk,reset,read_data,write_data,N,V,Z,w,mem_cmd,mem_addr,over); 

input clk, reset;
input [15:0] read_data; 
output [15:0] write_data; 
output N, V, Z, w; 
output[1:0]mem_cmd;
output[8:0]mem_addr;
output over;
wire addr_sel,load_pc,load_addr,load_ir;
wire [2:0]reset_pc;
wire [15:0]inreg_out;
wire [1:0] ALUop,shift,op;
wire [15:0] sximm8,sximm5;
wire [2:0] rnw,opcode;
wire [7:0] control;
wire [3:0] vsel;
wire [2:0] nsel;
wire [15:0] write_data;
wire [8:0] dataaddr_out;
wire [8:0]PC;
wire [2:0]cond;
wire [8:0]next_pc;
wire sximmsel;
wire aluen;
wire [1:0]aluin;
assign mem_addr=addr_sel?PC:dataaddr_out;

assign w=control[0];
assign aluin=aluen?ALUop:2'b00;
dreiMultiplexer mult(9'b0,(PC+1),write_data[8:0],reset_pc,next_pc);
register #(16)inreg(clk,load_ir,read_data,inreg_out);
InstructionDecoder indec (inreg_out,nsel,opcode,op,rnw,shift,sximm8,sximm5,ALUop,cond);
StateMachine FSM (clk,s,reset,opcode,op,cond,Z,V,N,control,vsel,nsel,mem_cmd,addr_sel,load_pc,load_addr,reset_pc,load_ir,over,sximmsel,aluen);
datapath DP (clk,rnw,vsel,control[7],control[6],shift,control[3],control[2],aluin,control[5],control[4],rnw,control[1],sximm8,sximm5,PC[7:0],read_data,sximmsel,Z,V,N,write_data);
register #(9) pc(clk,load_pc,next_pc,PC);
register #(9) dataaddr(clk,load_addr,write_data[8:0],dataaddr_out);
endmodule
//instruction decoder that decodes instructions to the datapath and state machine
module InstructionDecoder(data_in,nsel,opcode,op,rnw,shift,sximm8,sximm5,ALUop,cond);
   input [15:0] data_in;
   input [2:0] nsel;
   output [1:0]ALUop,shift,op;
   output [15:0]sximm8,sximm5;
   output [2:0] rnw,opcode;
   output [2:0]cond;
   assign ALUop=data_in[12:11];
   //changes to sximms
   assign sximm5={11'b00000000000,data_in[4:0]};
   assign sximm8=data_in[7]?{8'b11111111,data_in[7:0]}:{8'b00000000,data_in[7:0]};
   assign shift=data_in[4:3];
   assign opcode=data_in[15:13];
   assign op=data_in[12:11];
   assign cond=data_in[10:8];
   //a multiplexer to filter what signal to use for r/w
   assign rnw=({3{nsel[0]}}&data_in[2:0])|({3{nsel[1]}}&data_in[7:5])|({3{nsel[2]}}&data_in[10:8]);
endmodule

module dreiMultiplexer (ain,bin,cin,sel,out);
   parameter n=9;
   input [n-1:0]ain;
   input [n-1:0]bin;
   input [n-1:0]cin;
   input [2:0]sel;
   output[n-1:0]out;
   
   assign out=({n{sel[0]}}&ain)|({n{sel[1]}}&bin)|({n{sel[2]}}&cin);
endmodule

//things needed as output of the state machine: loada loadb loadc loads asel bsel write  w vsel nsel
module StateMachine(clk,s,reset,opcode,op,cond,Z,V,N,control,vsel,nsel,m_cmd,addr_sel,load_pc,load_addr,reset_pc,load_ir,over,sximmsel,aluen);
   input clk,s,reset;
   input [2:0]opcode;
   input [1:0]op;
   input [2:0]cond;
   input Z,V,N;
   
   output reg aluen;
   output reg over; 
   output reg[7:0]control;
   output reg[2:0] nsel;
   output reg[3:0] vsel;
   output reg[1:0] m_cmd;
   output reg addr_sel;
   output reg load_pc;
   output reg [2:0]reset_pc;
   output reg load_addr;
   output reg load_ir;
   output reg sximmsel;
   reg [2:0] state;
   reg [2:0]a;
   reg [19:0]p;
   always@(posedge clk)begin
   
      if(reset==1)begin
	    sximmsel=0;
	    control=8'b00000001;
		nsel=3'b000;
		vsel=4'b0000;
		reset_pc=3'b001;
		load_pc=1;
		m_cmd=2'b00;
		state=3'b000;
		addr_sel=0;
		load_ir=0;
		a=3'b000;
		p=20'h00000;
		over=0;
		aluen=1;

		end
		
	  else begin
	     casex(state)
		 3'b000:begin state=3'b001; addr_sel=1;m_cmd=2'b10;reset_pc=3'b010;load_pc=0; p=20'h10000; sximmsel=0;aluen=1;end
		 3'b001:begin state=3'b010; load_ir=1;p=20'h00000;end
		 3'b010:begin state=3'b011; load_pc=1;m_cmd=2'b00;addr_sel=0;load_ir=0;end
		 3'b011:begin
	     //makes sure that s only controls the wait stage  
         load_pc=0;
		  if(opcode==3'b110&&op==2'b10)begin //first opcode condition
		  //en=0;
		  casex({control,nsel,vsel})
		    15'b000000010000000: begin
			control=8'b00000010;
			nsel=3'b100;
			vsel=4'b0010;
			end
			//go back to reset oreginal state
			15'b000000101000010:begin
			 state=3'b000;
			 control=8'b00000001;
		     nsel=3'b000;
		     vsel=4'b0000;
			end
			
			default:begin 
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			end
		  endcase
		  end
		  
		  //-------
		  else if(opcode==3'b110&&op==2'b00)begin //second opcode condition
		     casex({control,nsel,vsel})
		    15'b000000010000000: begin
			control=8'b01000000;
			nsel=3'b001;
			vsel=4'b0000;
			end
			
			15'b010000000010000: begin
			control=8'b00111000;
			nsel=3'b000;
			vsel=4'b0000;
			end
			
			15'b001110000000000:begin
			control=8'b00000010;
			nsel=3'b010;
			vsel=4'b1000;
			end
			
			15'b000000100101000:begin
			control=8'b00000001;
		    nsel=3'b000;
		    vsel=4'b0000;
			state=3'b000;
			end
			
			default:begin 
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			end
			endcase
		  end
		  
		 else if(opcode==3'b101&&op==2'b11)begin //third opcode condition
		 
		     casex({control,nsel,vsel})
		    15'b000000010000000: begin
			control=8'b01000000;
			nsel=3'b001;
			vsel=4'b0000;
			end
			
			15'b010000000010000: begin
			control=8'b00111000;
			nsel=3'b000;
			vsel=4'b0000;
			end
			
			15'b001110000000000:begin
			control=8'b00000010;
			nsel=3'b010;
			vsel=4'b1000;
			end
			
			15'b000000100101000:begin
			control=8'b00000001;
		    nsel=3'b000;
		    vsel=4'b0000;
			state=3'b000;
			end
			
			default:begin 
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			end
			endcase
		 end
		  //---------
		  else if(opcode==3'b101&&(op==2'b00||op==2'b10))begin//fourth opcode condition
		  
		     casex({control,nsel,vsel})
			15'b000000010000000:begin
			control=8'b10000000;
			nsel=3'b100;
			vsel=4'b0000;
			   end
			
			15'b100000001000000:begin
			control=8'b01000000;
			nsel=3'b001;
			vsel=4'b0000;
			   end
			   
			15'b010000000010000:begin
			control=8'b00110000;
			nsel=3'b000;
			vsel=4'b0000;
			end
			
			15'b001100000000000:begin
			control=8'b00000010;
			nsel=3'b010;
			vsel=4'b1000;
			end
			15'b000000100101000:begin
			control=8'b00000001;
		    nsel=3'b000;
		    vsel=4'b0000;
			state=3'b000;
			end
			default:begin 
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			end
			 endcase
		  end
		  
		  else if(opcode==3'b101&&op==2'b01)begin//fifth condition
		
		    casex({control,nsel,vsel})
		    15'b000000010000000:begin
			control=8'b10000000;
			nsel=3'b100;
			vsel=4'b0000;
			   end
			15'b100000001000000:begin
			control=8'b01000000;
			nsel=3'b001;
			vsel=4'b0000;
			   end
			15'b010000000010000:begin
			control=8'b00110000;
			nsel=3'b000;
			vsel=4'b0000;
			end
			15'b001100000000000:begin
			control=8'b00000001;
		    nsel=3'b000;
		    vsel=4'b0000;
			state=3'b000;
			end
			//default stage
			default:begin 
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			end
            endcase
		  end
		//  loada loadb loadc loads asel bsel write  w  the ldr operation
		  else if(opcode==3'b011&&op==2'b00)begin
		     casex(a)
			 3'b000:begin
			 control=8'b10000000;
			 nsel=3'b100;
			 vsel=4'b0000;
			 {m_cmd,addr_sel,load_addr}=4'b0000;
			 a=3'b001;
			 end
			 3'b001:begin
			 control=8'b00110100;
			 nsel=3'b000;
			 vsel=4'b0000;
			 {m_cmd,addr_sel,load_addr}=4'b0000;
			 a=3'b010;
			 end
			 3'b010:begin
			 control=8'b00000000;
			 nsel=3'b000;
			 vsel=4'b0000;
			 {m_cmd,addr_sel,load_addr}=4'b10_01;
			 a=3'b011;
			 end
			 3'b011:begin
			 control=8'b00000000;
			 nsel=3'b000;
			 vsel=4'b0000;
			 {m_cmd,addr_sel,load_addr}=4'b1000;
			 a=3'b100;
			 end
			 3'b100:begin
			 control=8'b00000010;
			 nsel=3'b010;
			 vsel=4'b0001;
			 {m_cmd,addr_sel,load_addr}=4'b1000;
			 a=3'b101;
			 end

			 3'b101:begin
			 control=8'b00000001;
	       	 nsel=3'b000;
		     vsel=4'b0000;
			 state=3'b000;
			  {m_cmd,addr_sel,load_addr}=4'b0000;
			  			 a=3'b000;
			 end
			 default:begin
			 control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx; 
			 a=3'bxxx;
			 end
			 endcase
		     end
		  	//  loada loadb loadc loads asel bsel write  w  the write memory operation
			
			else if (opcode==3'b100&&op==2'b00)begin
	          //en=0;
			casex({control,nsel,vsel})
			 15'b000000010000000:begin
			 control=8'b10000000;
			 nsel=3'b100;
			 vsel=4'b0000;
			 end
			 15'b100000001000000:begin
			 control=8'b00110100;
			 nsel=3'b000;
			 vsel=4'b0000;
			 end
			 15'b001101000000000:begin
			 control=8'b00000000;
			 nsel=3'b000;
			 vsel=4'b0000;
			 {m_cmd,addr_sel,load_addr}=4'b00_01;
			end
			15'b0:begin
			  control=8'b01000000;
			  nsel=3'b010;
			  vsel=4'b0000;
			  {m_cmd,addr_sel,load_addr}=4'b00_00;
			end
			15'b010000000100000:begin
			  control=8'b00111000;
			  nsel=3'b000;
			  vsel=4'b0000;
			  {m_cmd,addr_sel,load_addr}=4'b00_00;
			end
			15'b001110000000000:begin
			  control=8'b0;
			  nsel=3'b0;
			  vsel=4'b1111;
			  {m_cmd,addr_sel,load_addr}=4'b01_00;
			end
			
			15'b000000000001111:begin
			control=8'b00000001;
	       	 nsel=3'b000;
		     vsel=4'b0000;
			 state=3'b000;
			{m_cmd,addr_sel,load_addr}=4'b0;
			end
			endcase
			end
			
			else if (opcode==3'b111)begin
			   control=8'bx;
			   vsel=8'bx;
			   nsel=3'bx;
			   state=3'b111;
			   over=1;
			end
			//loada loadb loadc loads asel bsel write  w vsel nsel
			//B
			else if(opcode==3'b001&&op==2'b00&&cond==3'b000)begin
				casex(a)
			   3'b000:begin control= 8'b10000000; vsel=4'b0100; nsel=3'b000;a=3'b001; end/*15'b000000010000000*/
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end/*15'b01000000_0010_000*/
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BEQ
			else if(opcode==3'b001&&op==2'b00&&cond==3'b001&&Z==1)begin
			  	  casex(a)
			   3'b000:begin control= 8'b10000000; vsel=4'b0100; nsel=3'b000;a=3'b001; end/*15'b000000010000000*/
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end/*15'b01000000_0010_000*/
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BEQ
			else if(opcode==3'b001&&op==2'b00&&cond==3'b001&&Z==0)begin
			  casex({control,nsel,vsel})
			   15'b000000010000000:begin control= 8'b00000001; vsel=4'b0000; nsel=3'b000;state=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BNE
			
			else if(opcode==3'b001&&op==2'b00&&cond==3'b010&&Z==0)begin
                 casex(a)
			   3'b000:begin control= 8'b10000000; vsel=4'b0100; nsel=3'b000;a=3'b001; end/*15'b000000010000000*/
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end/*15'b01000000_0010_000*/
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BNE
			else if(opcode==3'b001&&op==2'b00&&cond==3'b010&&Z==1)begin
			  casex({control,nsel,vsel})
               15'b000000010000000:begin control= 8'b00000001; vsel=4'b0000; nsel=3'b000;state=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			
			//loada loadb loadc loads asel bsel write  w vsel nsel
			//BLT
			else if(opcode==3'b001&&op==2'b00&&cond==3'b011&&(N!==V))begin
			  //en=0;
			  casex(a)
			   3'b000:begin control= 8'b10000000; vsel=4'b0100; nsel=3'b000;a=3'b001; end/*15'b000000010000000*/
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end/*15'b01000000_0010_000*/
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BLT
			else if(opcode==3'b001&&op==2'b00&&cond==3'b011&&(N==V))begin
			  casex({control,nsel,vsel})
			   15'b000000010000000:begin control= 8'b00000001; vsel=4'b0000; nsel=3'b000;state=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BLE
			
			else if(opcode==3'b001&&op==2'b00&&cond==3'b100&&((N!==V)||Z==1))begin
			    casex(a)
			   3'b000:begin control= 8'b10000000; vsel=4'b0100; nsel=3'b000;a=3'b001; end/*15'b000000010000000*/
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end/*15'b01000000_0010_000*/
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			
			//BLE
			else if(opcode==3'b001&&op==2'b00&&cond==3'b100&&(!((N!==V)||Z==1)))begin
			  casex({control,nsel,vsel})
			   15'b000000100000000:begin control= 8'b00000001; vsel=4'b0000; nsel=3'b000;state=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//loada loadb loadc loads asel bsel write  w vsel nsel
			//BL
			else if(opcode==3'b010&&op==2'b11)begin
			  aluen=0;
			  casex(a)
			   3'b000:begin control= 8'b10000010; vsel=4'b0100;nsel=3'b100;a=3'b001;end
			   3'b001:begin control= 8'b00100100; vsel=4'b0000; nsel=3'b000;a=3'b010;sximmsel=1; end/*15'b100000000100000*/
			   3'b010:begin control= 8'b00000000; vsel=4'b0000; nsel=3'b000;a=3'b011; reset_pc=3'b100;load_pc=1;sximmsel=0;end
			    3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000; end/*15'b000000000000000*/
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BX
			else if(opcode==3'b010&&op==2'b00)begin
			   aluen=0;
			  casex(a)
			   3'b000:begin control= 8'b01000000; vsel=4'b0000;nsel=3'b010;a=3'b001;end
			   3'b001:begin control= 8'b00101000; vsel=4'b0000;nsel=3'b000;a=3'b010;end
			   3'b010:begin control= 8'b00000000;vsel=4'b0000;nsel=3'b000;reset_pc=3'b100;load_pc=1;a=3'b011;end
			   3'b011:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
			//BLX
			else if(opcode==3'b010&&op==2'b10)begin
			  aluen=0;
			  casex(a)
			   3'b000:begin control= 8'b00000010; vsel=4'b0100;nsel=3'b100;a=3'b001;end
			   3'b001:begin control= 8'b01000000; vsel=4'b0000;nsel=3'b010;a=3'b010;end
			   3'b010:begin control= 8'b00101000; vsel=4'b0000;nsel=3'b000;a=3'b011;end
			   3'b011:begin control= 8'b00000000;vsel=4'b0000;nsel=3'b000;reset_pc=3'b100;load_pc=1;a=3'b100;end
			   3'b100:begin control= 8'b00000001;vsel=4'b0000;nsel=3'b000;state=3'b000;a=3'b000;end
			   default: begin control= 8'bx;vsel=4'bx;nsel=3'bx;state=3'bx; end
			  endcase
			end
		    else begin
		    control=8'bxxxxxxxx;
			 nsel=3'bxxx;
			 vsel=4'bxxxx;
		    end
		  
		  end
		  
		  default: state=3'bxxx;
		  endcase

		end
		
   end
endmodule

