`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:05:06 12/11/2014 
// Design Name: 
// Module Name:    Mblazetest 
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
module Mblazetest(
	input Clk,
	input Reset,
	input  [7:0] GPI1,
	output [7:0] GPO1,
	input UART_Rx,
	output UART_Tx
    );

	microblaze mcs_0 (
	  .Clk(Clk), // input Clk
	  .Reset(Reset), // input Reset
	  .UART_Rx(UART_Rx), // input UART_Rx
	  .UART_Tx(UART_Tx), // output UART_Tx
	  .FIT1_Interrupt(), // output FIT1_Interrupt
	  .FIT1_Toggle(), // output FIT1_Toggle
	  .GPO1(GPO1), // output [7 : 0] GPO1
	  .GPI1(GPI1), // input [7 : 0] GPI1
	  .GPI1_Interrupt(), // output GPI1_Interrupt
	  .INTC_IRQ() // output INTC_IRQ
	);
endmodule
