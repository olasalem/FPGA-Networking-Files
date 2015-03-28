/* $Id$ */
/******************************************************************************
*
* (c) Copyright 2012 Xilinx, Inc. All rights reserved.
*
* This file contains confidential and proprietary information of Xilinx, Inc.
* and is protected under U.S. and international copyright and other
* intellectual property laws.
*
* DISCLAIMER
* This disclaimer is not a license and does not grant any rights to the
* materials distributed herewith. Except as otherwise provided in a valid
* license issued to you by Xilinx, and to the maximum extent permitted by
* applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
* FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
* IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
* MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
* and (2) Xilinx shall not be liable (whether in contract or tort, including
* negligence, or under any other theory of liability) for any loss or damage
* of any kind or nature related to, arising under or in connection with these
* materials, including for any direct, or any indirect, special, incidental,
* or consequential loss or damage (including loss of data, profits, goodwill,
* or any type of loss or damage suffered as a result of any action brought by
* a third party) even if such damage or loss was reasonably foreseeable or
* Xilinx had been advised of the possibility of the same.
*
* CRITICAL APPLICATIONS
* Xilinx products are not designed or intended to be fail-safe, or for use in
* any application requiring fail-safe performance, such as life-support or
* safety devices or systems, Class III medical devices, nuclear facilities,
* applications related to the deployment of airbags, or any other applications
* that could lead to death, personal injury, or severe property or
* environmental damage (individually and collectively, "Critical
* Applications"). Customer assumes the sole risk and liability of any use of
* Xilinx products in Critical Applications, subject only to applicable laws
* and regulations governing limitations on product liability.
*
* THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
* AT ALL TIMES.
*
******************************************************************************/

/****************************************************************************/
/**
*
* @file xiomodule_uart.c
*
* Contains required functions for the XIOModule UART driver. See the
* xiomodule.h header file for more details on this driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.02a sa   07/25/12 First release
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xil_assert.h"
#include "xiomodule.h"
#include "xiomodule_i.h"
#include "xiomodule_l.h"

/************************** Constant Definitions ****************************/

/* The following constant defines the amount of error that is allowed for
 * a specified baud rate. This error is the difference between the actual
 * baud rate that will be generated using the specified clock and the
 * desired baud rate.
 */
#define XUN_MAX_BAUD_ERROR_RATE		3	 /* max % error allowed */

/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/
/************************** Function Prototypes *****************************/

static void StubHandler(void *CallBackRef, unsigned int ByteCount);

/****************************************************************************/
/**
*
* Initialize a XIOModule instance. This function disables the UART
* interrupts. The baud rate and format of the data are fixed in the hardware
* at hardware build time, except if programmable baud rate is selected.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	Config is a reference to a structure containing information
*		about a specific IO Module device. This function initializes an
*		InstancePtr object for a specific device specified by the
*		contents of Config. This function can initialize multiple
*		instance objects with the use of multiple calls giving different
*		Config information on each call.
* @param 	EffectiveAddr is the device register base address. Use
*		Config->BaseAddress for this parameters, passing the physical
*		address.
*
* @return
* 		- XST_SUCCESS if everything starts up as expected.
*
* @note		The Config and EffectiveAddress arguments are not used by this
*		function, but are provided to keep the function signature
*		consistent with other drivers.
*
*****************************************************************************/
int XIOModule_CfgInitialize(XIOModule *InstancePtr, XIOModule_Config *Config,
				u32 EffectiveAddr)
{
	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Set some default values, including setting the callback
	 * handlers to stubs.
	 */
	InstancePtr->SendBuffer.NextBytePtr = NULL;
	InstancePtr->SendBuffer.RemainingBytes = 0;
	InstancePtr->SendBuffer.RequestedBytes = 0;

	InstancePtr->ReceiveBuffer.NextBytePtr = NULL;
	InstancePtr->ReceiveBuffer.RemainingBytes = 0;
	InstancePtr->ReceiveBuffer.RequestedBytes = 0;

	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

	InstancePtr->RecvHandler = StubHandler;
	InstancePtr->SendHandler = StubHandler;

	/* 
	 * Modify the IER to disable the UART interrupts
	 */
	XIOModule_Uart_DisableInterrupt(InstancePtr);

	/*
	 * Clear the statistics for this driver
	 */
	XIOModule_ClearStats(InstancePtr);

	return XST_SUCCESS;
}

/****************************************************************************/
/**
*
* This functions sends the specified buffer of data using the UART in either
* polled or interrupt driven modes. This function is non-blocking such that it
* will return before the data has been sent by the UART. If the UART is busy
* sending data, it will return and indicate zero bytes were sent.
*
* In a polled mode, this function will only send as much data as the UART can
* buffer in the transmitter. The application may need to call it repeatedly to
* send a buffer.
*
* In interrupt mode, this function will start sending the specified buffer and
* then the interrupt handler of the driver will continue sending data until the
* buffer has been sent. A callback function, as specified by the application,
* will be called to indicate the completion of sending the buffer.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	DataBufferPtr is pointer to a buffer of data to be sent.
* @param	NumBytes contains the number of bytes to be sent. A value of
*		zero will stop a previous send operation that is in progress
*		in interrupt mode. Any data that was already put into the
*		transmit FIFO will be sent.
*
* @return	The number of bytes actually sent.
*
* @note		The number of bytes is not asserted so that this function may
*		be called with a value of zero to stop an operation that is
*		already in progress.
*
******************************************************************************/
unsigned int XIOModule_Send(XIOModule *InstancePtr, u8 *DataBufferPtr,
				unsigned int NumBytes)
{
	unsigned int BytesSent;
	u32 StatusRegister;

	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(DataBufferPtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(((signed)NumBytes) >= 0);

	/*
	 * Enter a critical region by disabling the UART interrupts to allow
	 * this call to stop a previous operation that may be interrupt driven.
	 */
	StatusRegister = InstancePtr->CurrentIER;
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
			StatusRegister & 0xFFFFFFF8);

	/*
	 * Setup the specified buffer to be sent by setting the instance
	 * variables so it can be sent with polled or interrupt mode
	 */
	InstancePtr->SendBuffer.RequestedBytes = NumBytes;
	InstancePtr->SendBuffer.RemainingBytes = NumBytes;
	InstancePtr->SendBuffer.NextBytePtr = DataBufferPtr;

	/*
	 * Restore the interrupt enable register to it's previous value such
	 * that the critical region is exited.
	 * This is done here to minimize the amount of time the interrupt is
	 * disabled since there is only one interrupt and the receive could
	 * be filling up while interrupts are blocked.
	 */
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
	    (InstancePtr->CurrentIER & 0xFFFFFFF8) | (StatusRegister & 0x7));

	/*
	 * Send the buffer using the UART and return the number of bytes sent
	 */
	BytesSent = XIOModule_SendBuffer(InstancePtr);

	return BytesSent;
}


/****************************************************************************/
/**
*
* This function will attempt to receive a specified number of bytes of data
* from the UART and store it into the specified buffer. This function is
* designed for either polled or interrupt driven modes. It is non-blocking
* such that it will return if no data has already received by the UART.
*
* In a polled mode, this function will only receive as much data as the UART
* can buffer in the receiver. The application may need to call it repeatedly to
* receive a buffer. Polled mode is the default mode of operation for the driver.
*
* In interrupt mode, this function will start receiving and then the interrupt
* handler of the driver will continue receiving data until the buffer has been
* received. A callback function, as specified by the application, will be called
* to indicate the completion of receiving the buffer or when any receive errors
* or timeouts occur.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	DataBufferPtr is pointer to buffer for data to be received into.
* @param	NumBytes is the number of bytes to be received. A value of zero
*		will stop a previous receive operation that is in progress in
*		interrupt mode.
*
* @return	The number of bytes received.
*
* @note 	The number of bytes is not asserted so that this function
*		may be called with a value of zero to stop an operation
*		that is already in progress.
*
*****************************************************************************/
unsigned int XIOModule_Recv(XIOModule *InstancePtr, u8 *DataBufferPtr,
				unsigned int NumBytes)
{
	unsigned int ReceivedCount;
	u32 StatusRegister;

	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(DataBufferPtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(((signed)NumBytes) >= 0);

	/*
	 * Enter a critical region by disabling all the UART interrupts to allow
	 * this call to stop a previous operation that may be interrupt driven
	 */
	StatusRegister = InstancePtr->CurrentIER;
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
			StatusRegister & 0xFFFFFFF8);

	/*
	 * Setup the specified buffer to be received by setting the instance
	 * variables so it can be received with polled or interrupt mode
	 */
	InstancePtr->ReceiveBuffer.RequestedBytes = NumBytes;
	InstancePtr->ReceiveBuffer.RemainingBytes = NumBytes;
	InstancePtr->ReceiveBuffer.NextBytePtr = DataBufferPtr;

	/*
	 * Restore the interrupt enable register to it's previous value such
	 * that the critical region is exited
	 */
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
	    (InstancePtr->CurrentIER & 0xFFFFFFF8) | (StatusRegister & 0x7));

	/*
	 * Receive the data from the UART and return the number of bytes
	 * received. This is done here to minimize the amount of time the
	 * interrupt is disabled.
	 */
	ReceivedCount = XIOModule_ReceiveBuffer(InstancePtr);

	return ReceivedCount;
}

/****************************************************************************/
/**
*
* This function does nothing, since the UART doesn't have any FIFOs. It is
* included for compatibility with the UART Lite driver.
*
* @param	InstancePtr is a pointer to the XIOModule instance .
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XIOModule_ResetFifos(XIOModule *InstancePtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
}

/****************************************************************************/
/**
*
* This function determines if the specified UART is sending data. If the
* transmitter register is not empty, it is sending data.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	A value of TRUE if the UART is sending data, otherwise FALSE.
*
* @note		None.
*
*****************************************************************************/
int XIOModule_IsSending(XIOModule *InstancePtr)
{
	u32 StatusRegister;

	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Read the status register to determine if the transmitter is empty
	 */
	StatusRegister = XIOModule_ReadReg(InstancePtr->BaseAddress,
						XUL_STATUS_REG_OFFSET);

	/*
	 * If the transmitter is not empty then indicate that the UART is still
	 * sending some data
	 */
	return ((StatusRegister & XUL_SR_TX_FIFO_FULL) == XUL_SR_TX_FIFO_FULL);
}

/****************************************************************************
*
* This function provides a stub handler such that if the application does not
* define a handler but enables interrupts, this function will be called.
*
* @param	CallBackRef has no purpose but is necessary to match the
*		interface for a handler.
* @param	ByteCount has no purpose but is necessary to match the
*		interface for a handler.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
static void StubHandler(void *CallBackRef, unsigned int ByteCount)
{
	/*
	 * Assert occurs always since this is a stub and should never be called
	 */
	Xil_AssertVoidAlways();
}

/****************************************************************************/
/**
*
* This function sends a buffer that has been previously specified by setting
* up the instance variables of the instance. This function is designed to be
* an internal function for the XIOModule component such that it may be called
* from a shell function that sets up the buffer or from an interrupt handler.
*
* This function sends the specified buffer of data to the UART in either
* polled or interrupt driven modes. This function is non-blocking such that
* it will return before the data has been sent by the UART.
*
* In a polled mode, this function will only send as much data as the UART can
* buffer in the transmitter. The application may need to call it repeatedly to
* send a buffer.
*
* In interrupt mode, this function will start sending the specified buffer and
* then the interrupt handler of the driver will continue until the buffer
* has been sent. A callback function, as specified by the application, will
* be called to indicate the completion of sending the buffer.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	NumBytes is the number of bytes actually sent (put into the
*		UART transmitter and/or FIFO).
*
* @note		None.
*
*****************************************************************************/
unsigned int XIOModule_SendBuffer(XIOModule *InstancePtr)
{
	unsigned int SentCount = 0;
	u8 StatusRegister;
	u8 IntrEnableStatus;

	/*
	 * Read the status register to determine if the transmitter is full
	 */
	StatusRegister = XIOModule_GetStatusReg(InstancePtr->BaseAddress);

	/*
	 * Enter a critical region by disabling all the UART interrupts to allow
	 * this call to stop a previous operation that may be interrupt driven
	 */
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
			StatusRegister & 0xFFFFFFF8);

	/*
	 * Save the status register contents to restore the interrupt enable
	 * register to it's previous value when that the critical region is
	 * exited
	 */
	IntrEnableStatus = StatusRegister;

	/*
	 * Fill the FIFO from the the buffer that was specified
	 */

	while (((StatusRegister & XUL_SR_TX_FIFO_FULL) == 0) &&
		(SentCount < InstancePtr->SendBuffer.RemainingBytes)) {
		XIOModule_WriteReg(InstancePtr->BaseAddress,
					XUL_TX_OFFSET,
					InstancePtr->SendBuffer.NextBytePtr[
					SentCount]);

		SentCount++;

		StatusRegister =
			XIOModule_GetStatusReg(InstancePtr->BaseAddress);
	}

	/*
	 * Update the buffer to reflect the bytes that were sent from it
	 */
	InstancePtr->SendBuffer.NextBytePtr += SentCount;
	InstancePtr->SendBuffer.RemainingBytes -= SentCount;

	/*
	 * Increment associated counters
	 */
	 InstancePtr->Uart_Stats.CharactersTransmitted += SentCount;

	/*
	 * Restore the interrupt enable register to it's previous value such
	 * that the critical region is exited
	 */
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
	    (InstancePtr->CurrentIER & 0xFFFFFFF8) | (IntrEnableStatus & 0x7));

	/*
	 * Return the number of bytes that were sent, althought they really were
	 * only put into the FIFO, not completely sent yet
	 */
	return SentCount;
}

/****************************************************************************/
/**
*
* This function receives a buffer that has been previously specified by setting
* up the instance variables of the instance. This function is designed to be
* an internal function for the XIOModule component such that it may be called
* from a shell function that sets up the buffer or from an interrupt handler.
*
* This function will attempt to receive a specified number of bytes of data
* from the UART and store it into the specified buffer. This function is
* designed for either polled or interrupt driven modes. It is non-blocking
* such that it will return if there is no data has already received by the
* UART.
*
* In a polled mode, this function will only receive as much data as the UART
* can buffer, either in the receiver or in the FIFO if present and enabled.
* The application may need to call it repeatedly to receive a buffer. Polled
* mode is the default mode of operation for the driver.
*
* In interrupt mode, this function will start receiving and then the interrupt
* handler of the driver will continue until the buffer has been received. A
* callback function, as specified by the application, will be called to indicate
* the completion of receiving the buffer or when any receive errors or timeouts
* occur.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	The number of bytes received.
*
* @note		None.
*
*****************************************************************************/
unsigned int XIOModule_ReceiveBuffer(XIOModule *InstancePtr)
{
	u8 StatusRegister;
	unsigned int ReceivedCount = 0;

	/*
	 * Loop until there is not more data buffered by the UART or the
	 * specified number of bytes is received
	 */

	while (ReceivedCount < InstancePtr->ReceiveBuffer.RemainingBytes) {
		/*
		 * Read the Status Register to determine if there is any data in
		 * the receiver
		 */
		StatusRegister =
			XIOModule_GetStatusReg(InstancePtr->BaseAddress);

		/*
		 * If there is data ready to be removed, then put the next byte
		 * received into the specified buffer and update the stats to
		 * reflect any receive errors for the byte
		 */
		if (StatusRegister & XUL_SR_RX_FIFO_VALID_DATA) {
			InstancePtr->ReceiveBuffer.NextBytePtr[ReceivedCount++]=
				XIOModule_ReadReg(InstancePtr->BaseAddress,
							XUL_RX_OFFSET);

			XIOModule_UpdateStats(InstancePtr, StatusRegister);
		}

		/*
		 * There's no more data buffered, so exit such that this
		 * function does not block waiting for data
		 */
		else {
			break;
		}
	}

	/*
	 * Enter a critical region by disabling all the UART interrupts to allow
	 * this call to stop a previous operation that may be interrupt driven
	 */
	StatusRegister = InstancePtr->CurrentIER;
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
			StatusRegister & 0xFFFFFFF8);

	/*
	 * Update the receive buffer to reflect the number of bytes that was
	 * received
	 */
	InstancePtr->ReceiveBuffer.NextBytePtr += ReceivedCount;
	InstancePtr->ReceiveBuffer.RemainingBytes -= ReceivedCount;

	/*
	 * Increment associated counters in the statistics
	 */
	InstancePtr->Uart_Stats.CharactersReceived += ReceivedCount;

	/*
	 * Restore the interrupt enable register to it's previous value such
	 * that the critical region is exited
	 */
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET,
	    (InstancePtr->CurrentIER & 0xFFFFFFF8) | (StatusRegister & 0x7));

	return ReceivedCount;
}

/****************************************************************************
*
* Sets the baud rate for the specified UART. Checks the input value for
* validity and also verifies that the requested rate can be configured to
* within the 3 percent error range for RS-232 communications. If the provided
* rate is not valid, the current setting is unchanged.
*
* This function is designed to be an internal function only used within the
* XIOModule component. It is necessary for initialization and for the user
* available function that sets the data format.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	BaudRate to be set in the hardware.
*
* @return
*		- XST_SUCCESS if everything configures as expected
* 		- XST_UART_BAUD_ERROR if the requested rate is not available
*		because there was too much error due to the input clock
*
* @note		None.
*
*****************************************************************************/
int XIOModule_SetBaudRate(XIOModule *InstancePtr, u32 BaudRate)
{
	u32 Baud8;
	u32 Baud16;
        u32 InputClockHz;
	u32 Divisor;
	u32 TargetRate;
	u32 Error;
	u32 PercentError;

	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Determine what the divisor should be to get the specified baud
	 * rate based upon the input clock frequency and a baud clock prescaler
	 * of 16, rounded to nearest divisor
	 */
	Baud8 = BaudRate << 3;
	Baud16 = Baud8 << 1;
        InputClockHz = InstancePtr->CfgPtr->InputClockHz;
	Divisor = (InputClockHz + Baud8) / Baud16;

	/*
	 * Check for too much error between the baud rate that will be generated
	 * using the divisor and the expected baud rate, ensuring that the error
	 * is positive due to rounding above
	 */
	TargetRate = Divisor * Baud16;
	if (InputClockHz < TargetRate)
		Error = TargetRate - InputClockHz;
	else
		Error = InputClockHz - TargetRate;

	/*
	 * Error has total error now compute the percentage multiplied by 100 to
	 * avoid floating point calculations, should be less than 3% as per
	 * RS-232 spec
	 */
	PercentError = (Error * 100UL) / InputClockHz;
	if (PercentError > XUN_MAX_BAUD_ERROR_RATE) {
		return XST_UART_BAUD_ERROR;
	}

	/*
	 * Write the baud rate divisor to the UART Baud Rate Register
	 */
	XIOModule_WriteReg(InstancePtr->BaseAddress,
			   XUL_BAUDRATE_OFFSET,
			   Divisor - 1);
	InstancePtr->CurrentUBRR = Divisor - 1;

	/*
	 * Save the baud rate in the instance so that the get baud rate function
	 * won't have to calculate it from the divisor
	 */
	InstancePtr->CfgPtr->BaudRate = BaudRate;

	return XST_SUCCESS;
}
