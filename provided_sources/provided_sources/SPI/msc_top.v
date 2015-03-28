`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:01:23 12/11/2014 
// Design Name: 
// Module Name:    msc_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module msc_top(
    input clk_fpga,
    input reset,
    input rx,
    input tx,
    input [7:0] switch,
    output [7:0] leds
    );
microblazeproc mcs_0 (
	 .Clk(clk_fpga),
	 .Reset(reset),
	 .UART_Rx(rx),
	 .UART_Tx(tx),
	 .GPO1(leds),
	 .GPI1(switch),
	 .GPI1_Interrupt()
);

endmodule
