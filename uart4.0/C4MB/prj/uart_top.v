
module uart_top(
    input sys_clk,
    input sys_rst_n,
	 input key,
    
	 output [3:0]led,
	 output [1:0]uart_txd
);
 

    data_generator u1(
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .trans_done(trans_en),
		  
        .instr(instr),
		  .led(led)
    );
    
    new_uart u2(
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .key(key),
        .str(instr),
		  
//		  .led(led),
        .uart_txd(uart_txd),
        .trans_en(trans_en)
    );    
 
endmodule