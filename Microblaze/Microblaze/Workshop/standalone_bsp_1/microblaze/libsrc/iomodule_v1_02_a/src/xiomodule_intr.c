/* $Id$ */
/******************************************************************************
*
* (c) Copyright 2011-2012 Xilinx, Inc. All rights reserved.
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
/*****************************************************************************/
/**
*
* @file xiomodule_intr.c
*
* This file contains the interrupt processing for the XIOModule component
* which is the driver for the Xilinx IO Module interrupt.  The interrupt
* processing is partitioned seperately such that users are not required to
* use the provided interrupt processing.  This file requires other files of
* the driver to be linked in also.
*
* Two different interrupt handlers are provided for this driver such that the
* user must select the appropriate handler for the application.  The first
* interrupt handler, XIOModule_VoidInterruptHandler, is provided for
* systems which use only a single interrupt controller or for systems that
* cannot otherwise provide an argument to the XIOModule interrupt handler
* (e.g., the RTOS interrupt vector handler may not provide such a facility).
* The constant XPAR_IOMODULE_SINGLE_DEVICE_ID must be defined for this
* handler to be included in the driver.  The second interrupt handler,
* XIOModule_InterruptHandler, uses an input argument which is an instance
* pointer to an interrupt controller driver such that multiple interrupt
* controllers can be supported.  This handler requires the calling function
* to pass it the appropriate argument, so another level of indirection may be
* required.
*
* Note that both of these handlers are now only provided for backward
* compatibility. The handler defined in xiomodule_l.c is the recommended
* handler.
*
* The interrupt processing may be used by connecting one of the interrupt
* handlers to the interrupt system.  These handlers do not save and restore
* the processor context but only handle the processing of the Interrupt
* Controller.  The two handlers are provided as working examples. The user is
* encouraged to supply their own interrupt handler when performance tuning is
* deemed necessary.
*
* This file also contains interrupt-related functions for the UART.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ---------------------------------------------------------
* 1.00a sa   07/15/11 First release
* 1.02a sa   07/25/12 Added UART interrupt related functions
* </pre>
*
* @internal
*
* This driver assumes that the context of the processor has been saved prior to
* the calling of the IO Module interrupt handler and then restored
* after the handler returns. This requires either the running RTOS to save the
* state of the machine or that a wrapper be used as the destination of the
* interrupt vector to save the state of the processor and restore the state
* after the interrupt handler returns.
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xil_assert.h"
#include "xbasic_types.h"
#include "xparameters.h"
#include "xiomodule.h"

/************************** Constant Definitions *****************************/

/*
 * Array of masks associated with the bit position, improves performance
 * in the ISR, this table is shared between all instances of the driver
 */
u32 XIOModule_TimerBitPosMask[XTC_DEVICE_TIMER_COUNT] = {
  1 << XIN_IOMODULE_PIT_1_INTERRUPT_INTR,
  1 << XIN_IOMODULE_PIT_2_INTERRUPT_INTR,
  1 << XIN_IOMODULE_PIT_3_INTERRUPT_INTR,
  1 << XIN_IOMODULE_PIT_4_INTERRUPT_INTR
};


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

static void ReceiveDataHandler(XIOModule *InstancePtr);
static void SendDataHandler(XIOModule *InstancePtr);

/************************** Variable Definitions *****************************/

typedef void (*Handler)(XIOModule *InstancePtr);

/*****************************************************************************/
/**
*
* Interrupt handler for the driver used when there can be no argument passed
* to the handler.  This function is provided mostly for backward compatibility.
* The user should use XIOModule_DeviceInterruptHandler(), defined in
* xiomodule_l.c, if possible.
*
* The user must connect this function to the interrupt system such that it is
* called whenever the devices which are connected to it cause an interrupt.
*
* @return	None.
*
* @note
*
* The constant XPAR_IOMODULE_SINGLE_DEVICE_ID must be defined for this handler
* to be included in the driver compilation.
*
******************************************************************************/
#ifdef XPAR_IOMODULE_SINGLE_DEVICE_ID
void XIOModule_VoidInterruptHandler()
{
	/* Use the single instance to call the main interrupt handler */
	XIOModule_DeviceInterruptHandler(
		 (void *) XPAR_IOMODULE_SINGLE_DEVICE_ID);
}
#endif

/*****************************************************************************/
/**
*
* The interrupt handler for the driver. This function is provided mostly for
* backward compatibility.  The user should use
* XIOModule_DeviceInterruptHandler(), defined in xiomodule_l.c when
* possible and pass the device ID of the interrupt controller device as its
* argument.
*
* The user must connect this function to the interrupt system such that it is
* called whenever the devices which are connected to it cause an interrupt.
*
* @param	InstancePtr is a pointer to the XIOModule instance to be
*               worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XIOModule_InterruptHandler(XIOModule * InstancePtr)
{
	/* Assert that the pointer to the instance is valid
	 */
	XASSERT_VOID(InstancePtr != NULL);

	/* Use the instance's device ID to call the main interrupt handler.
	 * (the casts are to avoid a compiler warning)
	 */
	XIOModule_DeviceInterruptHandler((void *)
			         ((u32) (InstancePtr->CfgPtr->DeviceId)));
}


/*****************************************************************************/
/**
*
* Sets the timer callback function, which the driver calls when the specified
* timer times out.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	FuncPtr is the pointer to the callback function.
*
* @return	None.
*
* @note
*
* The handler is called within interrupt context so the function that is
* called should either be short or pass the more extensive processing off
* to another task to allow the interrupt to return and normal processing
* to continue.
*
* This function is provided for compatibility, and only allows setting a
* single handler for all Programmable Interval Timers.
*
******************************************************************************/
void XIOModule_SetHandler(XIOModule * InstancePtr,
			  XIOModule_Timer_Handler FuncPtr,
			  void *CallBackRef)
{
	u8 Index;

	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(FuncPtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	InstancePtr->Handler = FuncPtr;
	InstancePtr->CallBackRef = CallBackRef;

	for (Index = XIN_IOMODULE_PIT_1_INTERRUPT_INTR;
	     Index <= XIN_IOMODULE_PIT_4_INTERRUPT_INTR; Index++) {
	    InstancePtr->CfgPtr->HandlerTable[Index].Handler =
	      XIOModule_Timer_InterruptHandler;
	}
}

/*****************************************************************************/
/**
*
* Interrupt Service Routine (ISR) for the driver.  This function only performs
* processing for the Programmable Interval Timere and does not save and restore
* the interrupt context.
*
* @param	InstancePtr contains a pointer to the IO Module instance for
*		the interrupt.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XIOModule_Timer_InterruptHandler(void *InstancePtr)
{
    XIOModule *IOModulePtr = NULL;
    u8 Index;
    u32 IntPendingReg, ModeMask;

    /*
     * Verify that each of the inputs are valid.
     */
    XASSERT_VOID(InstancePtr != NULL);

    /*
     * Convert the non-typed pointer to an IO Module instance pointer
     * such that there is access to the IO Module
     */
    IOModulePtr = (XIOModule *) InstancePtr;

    /*
     * Read the pending interrupts to be able to check if interrupt occurred
     */
    IntPendingReg = XIOModule_ReadReg(IOModulePtr->BaseAddress,
				      XIN_IPR_OFFSET);

    ModeMask = ~IOModulePtr->CurrentIMR;

    /*
     * Loop thru each timer in the device and call the callback function
     * for each timer which has caused an interrupt, but only if not fast
     */
    for (Index = 0; Index < XTC_DEVICE_TIMER_COUNT; Index++) {
	/*
	 * Check if timer is enabled
	 */
	if (IOModulePtr->CfgPtr->PitUsed[Index]) {

	    /*
	     * Check if timer expired and interrupt occured,
	     * but only if it is not a fast interrupt
	     */
	    if (IntPendingReg & ModeMask & XIOModule_TimerBitPosMask[Index]) {

		/*
		 * Increment statistics for the number of interrupts and call
		 * the callback to handle any application specific processing
		 */
		IOModulePtr->Timer_Stats[Index].Interrupts++;

		IOModulePtr->Handler(IOModulePtr->CallBackRef, Index);

		/*
		 * Acknowledge the interrupt in the interrupt controller
		 * acknowledge register to mark it as handled
		 */
		XIOModule_WriteReg(IOModulePtr->BaseAddress,
				   XIN_IAR_OFFSET,
				   XIOModule_TimerBitPosMask[Index]);
	    }
	}
    }
}


/****************************************************************************/
/**
*
* This function sets the handler that will be called when an event (interrupt)
* occurs in the driver for the UART. The purpose of the handler is to allow
* application specific processing to be performed.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
* @param	FuncPtr is the pointer to the callback function.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
*
* @return	None.
*
* @note		There is no assert on the CallBackRef since the driver doesn't
*		know what it is (nor should it)
*
*****************************************************************************/
void XIOModule_SetRecvHandler(XIOModule *InstancePtr,
				XIOModule_Handler FuncPtr, void *CallBackRef)
{
	/*
	 * Assert validates the input arguments
	 * CallBackRef not checked, no way to know what is valid
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(FuncPtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	InstancePtr->RecvHandler = FuncPtr;
	InstancePtr->RecvCallBackRef = CallBackRef;
}

/****************************************************************************/
/**
*
* This function sets the handler that will be called when an event (interrupt)
* occurs in the driver for the UART. The purpose of the handler is to allow
* application specific processing to be performed.
*
* @param	InstancePtr is a pointer to the XIOModule instance .
* @param	FuncPtr is the pointer to the callback function.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
*
* @return 	None.
*
* @note		There is no assert on the CallBackRef since the driver doesn't
*		know what it is (nor should it)
*
*****************************************************************************/
void XIOModule_SetSendHandler(XIOModule *InstancePtr,
				XIOModule_Handler FuncPtr, void *CallBackRef)
{
	/*
	 * Assert validates the input arguments
	 * CallBackRef not checked, no way to know what is valid
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(FuncPtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	InstancePtr->SendHandler = FuncPtr;
	InstancePtr->SendCallBackRef = CallBackRef;
}

/****************************************************************************/
/**
*
* This function is the interrupt handler for the UART.
* It must be connected to an interrupt system by the user such that it is
* called when an interrupt for any UART lite occurs. This function
* does not save or restore the processor context such that the user must
* ensure this occurs.
*
* @param	InstancePtr contains a pointer to the instance of the IOModule
*		that the interrupt is for.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XIOModule_Uart_InterruptHandler(XIOModule *InstancePtr)
{
	u32 IsrStatus;

	Xil_AssertVoid(InstancePtr != NULL);

	/*
	 * Read the status register to determine which, could be both,
	 * interrupt is active
	 */
	IsrStatus = XIOModule_ReadReg(InstancePtr->BaseAddress,
					XIN_IPR_OFFSET);

	if ((IsrStatus & XUL_SR_RX_FIFO_VALID_DATA) != 0) {
		ReceiveDataHandler(InstancePtr);
	}

	if (((IsrStatus & XUL_SR_TX_FIFO_FULL) == XUL_SR_TX_FIFO_FULL) &&
		(InstancePtr->SendBuffer.RequestedBytes > 0)) {
		SendDataHandler(InstancePtr);
	}
}

/****************************************************************************/
/**
*
* This function handles the interrupt when data is received, either a single
* byte when FIFOs are not enabled, or multiple bytes with the FIFO.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
static void ReceiveDataHandler(XIOModule *InstancePtr)
{
	/*
	 * If there are bytes still to be received in the specified buffer
	 * go ahead and receive them
	 */
	if (InstancePtr->ReceiveBuffer.RemainingBytes != 0) {
		XIOModule_ReceiveBuffer(InstancePtr);
	}

	/*
	 * If the last byte of a message was received then call the application
	 * handler, this code should not use an else from the previous check of
	 * the number of bytes to receive because the call to receive the buffer
	 * updates the bytes to receive
	 */
	if (InstancePtr->ReceiveBuffer.RemainingBytes == 0) {
		InstancePtr->RecvHandler(InstancePtr->RecvCallBackRef,
		InstancePtr->ReceiveBuffer.RequestedBytes -
		InstancePtr->ReceiveBuffer.RemainingBytes);
	}

	/*
	 * Update the receive stats to reflect the receive interrupt
	 */
	InstancePtr->Uart_Stats.ReceiveInterrupts++;
}

/****************************************************************************/
/**
*
* This function handles the interrupt when data has been sent, the transmit
* FIFO is empty (transmitter holding register).
*
* @param	InstancePtr is a pointer to the XIOModule instance .
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
static void SendDataHandler(XIOModule *InstancePtr)
{
	/*
	 * If there are not bytes to be sent from the specified buffer,
	 * call the callback function
	 */
	if (InstancePtr->SendBuffer.RemainingBytes == 0) {
		int SaveReq;

		/*
		 * Save and zero the requested bytes since transmission
		 * is complete
		 */
		SaveReq = InstancePtr->SendBuffer.RequestedBytes;
		InstancePtr->SendBuffer.RequestedBytes = 0;

		/*
		 * Call the application handler to indicate
		 * the data has been sent
		 */
		InstancePtr->SendHandler(InstancePtr->SendCallBackRef, SaveReq);
	}
	/*
	 * Otherwise there is still more data to send in the specified buffer
	 * so go ahead and send it
	 */
	else {
		XIOModule_SendBuffer(InstancePtr);
	}

	/*
	 * Update the transmit stats to reflect the transmit interrupt
	 */
	InstancePtr->Uart_Stats.TransmitInterrupts++;
}


/*****************************************************************************/
/**
*
* This function disables the UART interrupt. After calling this function,
* data may still be received by the UART but no interrupt will be generated
* since the hardware device has no way to disable the receiver.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XIOModule_Uart_DisableInterrupt(XIOModule *InstancePtr)
{
	u32 NewIER;

	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Write to the interupt enable register to disable the UART
	 * interrupts.
	 */
	NewIER = InstancePtr->CurrentIER & 0xFFFFFFF8;
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET, NewIER);
	InstancePtr->CurrentIER = NewIER;
}

/*****************************************************************************/
/**
*
* This function enables the UART interrupts such that an interrupt will occur
* when data is received or data has been transmitted.
*
* @param	InstancePtr is a pointer to the XIOModule instance.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XIOModule_Uart_EnableInterrupt(XIOModule *InstancePtr)
{
	u32 NewIER;

	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Write to the interrupt enable register to enable the interrupts.
	 */
	NewIER = InstancePtr->CurrentIER | 0x7;
	XIomodule_Out32(InstancePtr->BaseAddress + XIN_IER_OFFSET, NewIER);
	InstancePtr->CurrentIER = NewIER;
}
