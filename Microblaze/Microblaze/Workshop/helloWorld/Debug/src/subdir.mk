################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

CC_SRCS += \
../src/main.cc 

OBJS += \
./src/main.o 

CC_DEPS += \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.cc
	@echo Building file: $<
	@echo Invoking: MicroBlaze g++ compiler
	mb-g++ -Wall -O0 -g3 -c -fmessage-length=0 -Wl,--no-relax -I../../standalone_bsp_3/microblaze/include -mno-xl-reorder -mlittle-endian -mcpu=v8.40.a -mxl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


