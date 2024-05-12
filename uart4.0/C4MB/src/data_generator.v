module data_generator(
    input	           sys_clk,             //系统时钟
    input              sys_rst_n,           //系统复位，低电平有效
	 input				  trans_done,
    

	 output  wire       [119:0]instr,  //指令发送完成标志
	 output  reg       [3:0]  led           //LED输出信号
    );
integer pointer=0;
integer left;

reg [119:0]str1;
reg [119:0]str2;
reg [119:0]str3;
//数据生成文件
initial begin
	str1="#000P1500T1000!";
	str2="#001P2500T1000!";
	str3="#002P3500T1400!";
	for(left=0;left<8;left=left+1)
		begin
		reg [119:0]temp;
		temp=str1[((left+1)*8-1)-:8];
		str1[((left+1)*8-1)-:8]=str1[((15-left)*8-1)-:8];
		str1[((15-left)*8-1)-:8]=temp;
		
		temp=str2[((left+1)*8-1)-:8];
		str2[((left+1)*8-1)-:8]=str2[((15-left)*8-1)-:8];
		str2[((15-left)*8-1)-:8]=temp;
		
		temp=str3[((left+1)*8-1)-:8];
		str3[((left+1)*8-1)-:8]=str3[((15-left)*8-1)-:8];
		str3[((15-left)*8-1)-:8]=temp;
		end
end

always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n)                                  
	     pointer<=0;
	 else if(trans_done==1)
		  pointer<=pointer+1;

end
//always @(*) begin
//	case(pointer)
//		0:instr<=str1;
//		1:instr<=str2;
//		2:instr<=str3;
//		default: instr<=str3;
//	endcase
//end
//endmodule
assign instr=str1;
always @(*)  begin
	led<=4'b1100;
end
endmodule



