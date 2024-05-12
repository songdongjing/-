//自动传输线上传来的数据
module uart_send(
    input	           sys_clk,             //系统时钟
    input              sys_rst_n,           //系统复位，低电平有效
	 input				  key,
	 input             [119:0]instr,			//指令输入口
    
    output  reg        [1:0]uart_txd,             //UART发送端口
    output  reg  [3:0]  led,           //LED输出信号
	 output  wire        trans_done  //指令发送完成标志
    );
    
//parameter define
parameter  CLK_FREQ = 50000000;             //系统时钟频率
parameter  UART_BPS = 9600;                 //串口波特率
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;   //为得到指定波特率，对系统时钟计数BPS_CNT次


reg [7:0]uart_din_array[14:0];
reg [119:0]str;
reg [7:0]temp;



//reg define 
reg        tx_flag;//正在发送标志
reg [7:0]  tx_data;//准备发送的数据
reg [3:0]  tx_cnt;//发送的位数
//reg [5:0]  word_cnt=5;//发送的字符数
integer word_cnt=0;
integer key_flag=1;
reg [15:0] clk_cnt;                           //系统时钟计数器

integer left;
//#000P1500T1000!对应ascii码
initial begin
	led=4'b0000;
	str="#000P1500T1000!";
	
	for(left=0;left<8;left=left+1)
		begin
		temp=str[((left+1)*8-1)-:8];
		str[((left+1)*8-1)-:8]=str[((15-left)*8-1)-:8];
		str[((15-left)*8-1)-:8]=temp;
		end
//	str="!0001T0051P000#";
end


//*****************************************************
//**                    main code
//*****************************************************
//寄存待发送的数据，并进入发送过程          
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end 
    else    if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16))  && (word_cnt == 14)) begin                                       
            tx_flag <= 1'b0;                //发送过程结束，标志位tx_flag拉低
            tx_data <= 1;
				trans_done <= 1 ;
				end
	 else    if(key== 0)  begin //按键按下开始发送 发送过程
				led<=4'b1000;
				tx_data <= instr[((word_cnt+1)*8-1)-:8];  //寄存待发送的数据
				trans_done <= 0 ;   //发送过程
				if(key_flag==1) begin
					tx_flag <= 1'b1;                //进入发送过程，标志位tx_flag拉高 
					key_flag=0;
									end
				end
	 else    begin     //按键松开，重置按键
				tx_data <= instr[((word_cnt+1)*8-1)-:8];  //寄存待发送的数据
				tx_flag <= tx_flag;
				led<=4'b0000;
				key_flag=1;
				trans_done <= 0 ;//发送过程
				end
				
                                            //计数到停止位结束时，停止发送过程		
end

//进入发送过程后，启动系统时钟计数器
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if (tx_flag) begin                 //处于发送过程
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;               //对系统时钟计数达一个波特率周期后清零
	 end
    else                             
        clk_cnt <= 16'd0; 				        //发送过程结束
end

//进入发送过程后，启动发送数据计数器
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        tx_cnt <= 4'd0;
    else if (tx_flag) begin               //处于发送过程
        if (clk_cnt == BPS_CNT - 1 &&tx_cnt < 4'd10)			//对系统时钟计数达一个波特率周期
            tx_cnt <= tx_cnt + 1'b1;		//此时发送数据计数器加1
        else if(tx_cnt==10)
				tx_cnt<=4'd0;
		  else
            tx_cnt <= tx_cnt;       
		  end
    else                              
        tx_cnt  <= 4'd0;				    //发送过程结束
		  
end
//启动发送数据位数计数器
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        word_cnt <= 0;
    else if (tx_flag) begin               //处于发送过程
        if (tx_cnt == 9&&clk_cnt == BPS_CNT - 1)			//发送完一个字节且时钟清零时
            word_cnt <= word_cnt + 1;		//数据索引加一
        else if(word_cnt==15)
				word_cnt<=0;
		  else
            word_cnt <= word_cnt;       
		  end
    else                              
        word_cnt  <= 0;				    //发送过程结束
		  
end
always @(*) uart_txd[1]<=uart_txd[0];
//根据发送数据计数器来给uart发送端口赋值
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n)  
        uart_txd[0] <= 1'b1;        
    else if (tx_flag) 
        case(tx_cnt)
            4'd0: uart_txd[0] <= 1'b0;         //起始位 
            4'd1: uart_txd[0] <= tx_data[0];   //数据位最低位
            4'd2: uart_txd[0] <= tx_data[1];
            4'd3: uart_txd[0] <= tx_data[2];
            4'd4: uart_txd[0] <= tx_data[3];
            4'd5: uart_txd[0] <= tx_data[4];
            4'd6: uart_txd[0] <= tx_data[5];
            4'd7: uart_txd[0] <= tx_data[6];
            4'd8: uart_txd[0] <= tx_data[7];   //数据位最高位
            4'd9: uart_txd[0] <= 1'b1;         //停止位
            default: ;
        endcase
    else 
        uart_txd[0] <= 1'b1;                   //空闲时发送端口为高电平
end

endmodule	          