/*
 * Empty C++ Application
 */
#include <stdio.h>
#include "xparameters.h"
#include "xiomodule.h"
int main()
{
	u32 data;
	XIOModule gpi;
	XIOModule gpo;

	data = XIOModule_Initialize(&gpi, XPAR_IOMODULE_0_DEVICE_ID);
	data = XIOModule_Start(&gpi);

	data = XIOModule_Initialize(&gpo, XPAR_IOMODULE_0_DEVICE_ID);
	data = XIOModule_Start(&gpo);

	while(1){

		data = XIOModule_DiscreteRead(&gpi,1);
		XIOModule_DiscreteWrite(&gpo, 1, data);
	}

	return 0;
}
