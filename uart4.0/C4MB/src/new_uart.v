//输出多个舵机指令


module new_uart(
	input wire sys_clk,
	input wire sys_rst_n,
	input wire key,
//	input wire [119:0]str,
	
//	output  reg  [3:0]  led,           //LED输出信号
	output reg [1:0]uart_txd,
	output wire trans_en //为1表示正在发送，为0表示发送结束
	);



parameter  CLK_FREQ = 50000000;             //系统时钟频率
parameter  UART_BPS = 115200;                 //串口波特率
localparam  BPS_CNT  = CLK_FREQ /UART_BPS ;   //为得到指定波特率，对系统时钟计数BPS_CNT次


integer clk_cnt;
integer tx_cnt;
integer word_cnt=0;

reg trans_done;
reg trans_free;
reg tx_flag;
reg key_en;


reg key_en1;
reg key_en2;

//********************************************函数
function [119:0] instr_cal(input integer ID,PWM,t);//输入:舵机ID，PWM，时间   输出:指令
	begin
		instr_cal="#000P1500T1000!";
		instr_cal[8*15-1-:8]="!";
		//时间赋值
		instr_cal[8*14-1-:8]=t%10+48;
		instr_cal[8*13-1-:8]=t/10%10+48;
		instr_cal[8*12-1-:8]=t/100%10+48;
		instr_cal[8*11-1-:8]=t/1000+48;
		
		instr_cal[8*10-1-:8]="T";
		//PWM赋值
		instr_cal[8*9-1-:8]=PWM%10+48;
		instr_cal[8*8-1-:8]=PWM/10%10+48;
		instr_cal[8*7-1-:8]=PWM/100%10+48;
		instr_cal[8*6-1-:8]=PWM/1000+48;
		
		instr_cal[8*5-1-:8]="P";
		//ID赋值
		instr_cal[8*4-1-:8]=ID+48;
		instr_cal[8*3-1-:8]="0";
		instr_cal[8*2-1-:8]="0";
		
		instr_cal[8*1-1-:8]="#";
	end
endfunction
function [639:0] all_instr_cal(input integer number,ID0,ID1,ID2,ID3,ID4,PWM0,PWM1,PWM2,PWM3,PWM4,t0,t1,t2,t3,t4);//输入:舵机ID，PWM，时间   输出:指令
	begin

		all_instr_cal[8*5+120*5-1-:120]=instr_cal(ID4,PWM4,t4);
		all_instr_cal[8*5+120*4-1-:120]=instr_cal(ID3,PWM3,t3);
		all_instr_cal[8*5+120*3-1-:120]=instr_cal(ID2,PWM2,t2);
		all_instr_cal[8*5+120*2-1-:120]=instr_cal(ID1,PWM1,t1);
		all_instr_cal[8*5+120*1-1-:120]=instr_cal(ID0,PWM0,t0);
		all_instr_cal[8*5-1-:8]=number+48;
		all_instr_cal[8*4-1-:8]="0";
		all_instr_cal[8*3-1-:8]="0";
		all_instr_cal[8*2-1-:8]="0";
		
		all_instr_cal[8*1-1-:8]="G";

	end
endfunction
//********************************************

//********************************************测试代码
reg [639:0]instr_array;
reg [639:0]instr;
initial begin
	instr_array=all_instr_cal(0,0,1,2,3,5,1500,1500,1500,1500,1500,1000,1000,1000,1000,1000);
	trans_done=0;
	instr<=instr_array[3];
end

integer pointer=0;
always @(posedge trans_done) begin
	pointer=pointer+1;
  case(pointer)
		0: instr_array=all_instr_cal(0,0,1,2,3,5,1500,1500,1500,1500,1500,1000,1000,1000,1000,1000);
		1: instr_array=all_instr_cal(1,0,1,2,3,5,1500,1500,1900,750,1500,1000,1000,1000,1000,1000);  
		2: instr_array=all_instr_cal(2,0,1,2,3,5,1920,900,1500,900,1500,1000,1000,1000,1000,1000);
		3: instr_array=all_instr_cal(3,0,1,2,3,5,1500,1500,1900,730,2500,1000,1000,1000,1000,1000);
		4: instr_array=all_instr_cal(4,0,1,2,3,5,1100,1250,2000,1050,2500,1000,1000,1000,1000,1000);
		5: instr_array=all_instr_cal(5,0,1,2,3,5,1500,1500,1900,730,1500,1000,1000,1000,1000,1000);
		default: ;
  endcase
	instr<=instr_array;

end
//integer PWM=1500,t=1000;
//always @(posedge trans_done) begin
//	PWM=PWM+100;
//	instr_array[3]=instr_cal(1,PWM,t);
//end

//always @(*) begin
//	instr<=instr_array[pointer];
//end
//********************************************测试代码



//*****************************************************
//**                    main code
//*****************************************************
//always @(*) begin
//	if(key==1) led<=4'b0101;
//	else led<=4'b1010;
//end




assign trans_en=trans_done;//发送结束信号

//******************************计数器按键使能端口
//always @(*) key_en=key_en1&(~key_en2);//按键上升沿触发
//always @(posedge sys_clk)	begin //通过一个延迟的信号完成按键上升沿检测
//	key_en1<=key;
//	key_en2<=key_en1;
//end
//always @(*) tx_flag=(key_en&trans_free)|(~trans_free);  //按键使能且发送等待阶段，开始发送
//发送标志为：①按过键②发送未结束
reg key_flag=0;
always @(posedge key) key_flag=1;

always @(*) begin
	if(key_flag==1&&pointer!=6)
		tx_flag=1;
	else
		tx_flag=0;
end
		
//连续发送代码
//！！！！!!!!!!!!!!!!!!!!!!!!!!!!!不行就解注释
//reg key_enable=0;
//always @(*)  begin
//	if (key_en==1)
//		key_enable=1;
//	if	(pointer==5)
//		key_enable=0;
//end
//		
//always @(*)	tx_flag=(key_enable&trans_free)|(~trans_free);  //按键使能且发送等待阶段，开始发送
////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//******************************
//always @(*) begin
//		if(tx_flag==1) led<=4'b0101;
//end



//*************************波特率计数器

always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if (tx_flag) begin                 //处于发送过程
        if (clk_cnt < BPS_CNT - 1)			//计数周期为一个波特率周期，计数间隔为时钟频率
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;   
	 end
    else                             
        clk_cnt <= 16'd0; 				        //发送过程结束
end
//*************************



//*************************位计数器

always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        tx_cnt <= 4'd0;
    else if (tx_flag) begin               //处于发送过程
        if (clk_cnt == BPS_CNT - 1 &&tx_cnt < 4'd10)		//计数周期为0~9，共10位	计数间隔为波特率计数器的输出
            tx_cnt <= tx_cnt + 1'b1;		
        else if(tx_cnt==10)	
				tx_cnt<=4'd0;
		  else
            tx_cnt <= tx_cnt;       
		  end
    else                              
        tx_cnt  <= 4'd0;				    //发送过程结束
		  
end
//*************************



//*************************字符计数器

integer max_word_cnt=80;
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        word_cnt <= 0;
    else if (tx_flag) begin               //处于发送过程
        if (tx_cnt == 9&&clk_cnt == BPS_CNT - 1)			//计数周期为0~15，计数间隔为位计数器的输出
            word_cnt <= word_cnt + 1;		//数据索引加一
				
        else if(word_cnt==max_word_cnt) begin//指令发送结束,等待下一次按键
				word_cnt<=0;
				trans_free<=1;//进入等待发送阶段
				trans_done<=1; //标记发送结束
		  end
		  else begin
            word_cnt <= word_cnt;  
				trans_free<=0;//发送阶段
				trans_done<=0;//发送未结束
		  end
	 end
    else begin
		  trans_free<=1;//等待发送阶段
		  trans_done<=0;//发送未结束
        word_cnt  <= 0;		
	 end	  
		  
end
//*************************


//*************************数据选择器，根据位计数器的值选择数据发送
always @(*) uart_txd[1]<=uart_txd[0];

//根据发送数据计数器来给uart发送端口赋值
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)  
        uart_txd[0] <= 1'b1;        
    else if (tx_flag) 
        case(tx_cnt)
            4'd0: uart_txd[0] <= 1'b0;         //起始位 
            4'd1: uart_txd[0] <= instr[word_cnt*8];   //数据位最低位
            4'd2: uart_txd[0] <= instr[word_cnt*8+1];
            4'd3: uart_txd[0] <= instr[word_cnt*8+2];
            4'd4: uart_txd[0] <= instr[word_cnt*8+3];
            4'd5: uart_txd[0] <= instr[word_cnt*8+4];
            4'd6: uart_txd[0] <= instr[word_cnt*8+5];
            4'd7: uart_txd[0] <= instr[word_cnt*8+6];
            4'd8: uart_txd[0] <= instr[word_cnt*8+7];   //数据位最高位
            4'd9: uart_txd[0] <= 1'b1;         //停止位
            default: ;
        endcase
    else 
        uart_txd[0] <= 1'b1;                   //空闲时发送端口为高电平
end
//*************************字符计数器



endmodule	
