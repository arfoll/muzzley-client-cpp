################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../text/ascii.cpp \
../text/base64.cpp \
../text/convert.cpp \
../text/manip.cpp \
../text/url.cpp \
../text/utf8.cpp 

OBJS += \
./text/ascii.o \
./text/base64.o \
./text/convert.o \
./text/manip.o \
./text/url.o \
./text/utf8.o 

CPP_DEPS += \
./text/ascii.d \
./text/base64.d \
./text/convert.d \
./text/manip.d \
./text/url.d \
./text/utf8.d 


# Each subdirectory must supply rules for building sources it contributes
text/%.o: ../text/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: Cross G++ Compiler'
	g++ -std=c++0x -DMUZZLEY_DEBUG -I../ -O3 -Wall -c -fmessage-length=0 -fPIC -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


