# MSPM0G3507 standalone Arm GNU Toolchain build

PROJECT_NAME ?= firmware
MSPM0_SDK_ROOT ?= D:/ti/mspm0_sdk_2_04_00_06
GCC_ARM_ROOT ?= D:/stm32CubeMX/STM32CubeCLT_1.21.0/GNU-tools-for-STM32
SYSCONFIG_ROOT ?= D:/ti/SYSCONFIG
BUILD_DIR ?= build
OPT_LEVEL ?= -O2

SOURCE_DIR := src
INCLUDE_DIR := include
CONFIG_DIR := config
OBJECT_DIR := $(BUILD_DIR)/obj
SYSCONFIG_DIR := $(BUILD_DIR)/syscfg

SYSCONFIG_FILE := $(CONFIG_DIR)/app.syscfg
PRODUCT_JSON := $(MSPM0_SDK_ROOT)/.metadata/product.json
LINKER_SCRIPT := $(SYSCONFIG_DIR)/device_linker.lds
STARTUP_SOURCE := $(MSPM0_SDK_ROOT)/source/ti/devices/msp/m0p/startup_system_files/gcc/startup_mspm0g350x_gcc.c

CC := "$(GCC_ARM_ROOT)/bin/arm-none-eabi-gcc.exe"
SIZE := "$(GCC_ARM_ROOT)/bin/arm-none-eabi-size.exe"
OBJCOPY := "$(GCC_ARM_ROOT)/bin/arm-none-eabi-objcopy.exe"
SYSCONFIG_CLI := "$(SYSCONFIG_ROOT)/sysconfig_cli.bat"

# Recursively collect C sources while preserving their path below src/.
# Example: src/drivers/uart.c -> build/obj/drivers/uart.o
rwildcard = $(foreach item,$(wildcard $1*),$(call rwildcard,$(item)/,$2) $(filter $(subst *,%,$2),$(item)))
USER_SOURCES := $(strip $(call rwildcard,$(SOURCE_DIR)/,*.c))
USER_OBJECTS := $(patsubst $(SOURCE_DIR)/%.c,$(OBJECT_DIR)/%.o,$(USER_SOURCES))
SYSCONFIG_SOURCE := $(SYSCONFIG_DIR)/ti_msp_dl_config.c
SYSCONFIG_HEADER := $(SYSCONFIG_DIR)/ti_msp_dl_config.h
SYSCONFIG_OBJECT := $(OBJECT_DIR)/ti_msp_dl_config.o
STARTUP_OBJECT := $(OBJECT_DIR)/startup_mspm0g350x_gcc.o
OBJECTS := $(USER_OBJECTS) $(SYSCONFIG_OBJECT) $(STARTUP_OBJECT)
DEPENDENCIES := $(OBJECTS:.o=.d)

DEVICE_OPT := $(SYSCONFIG_DIR)/device.opt
GENERATED_LIBS := $(SYSCONFIG_DIR)/device.lds.genlibs
SYSCONFIG_OUTPUTS := $(SYSCONFIG_SOURCE) $(SYSCONFIG_HEADER) $(DEVICE_OPT) $(LINKER_SCRIPT) $(GENERATED_LIBS)

OUTPUT := $(BUILD_DIR)/$(PROJECT_NAME).out
MAP_FILE := $(BUILD_DIR)/$(PROJECT_NAME).map
HEX_FILE := $(BUILD_DIR)/$(PROJECT_NAME).hex
BIN_FILE := $(BUILD_DIR)/$(PROJECT_NAME).bin

CFLAGS := \
	-I$(INCLUDE_DIR) \
	-I$(SYSCONFIG_DIR) \
	@$(DEVICE_OPT) \
	$(OPT_LEVEL) \
	"-I$(MSPM0_SDK_ROOT)/source/third_party/CMSIS/Core/Include" \
	"-I$(MSPM0_SDK_ROOT)/source" \
	-mcpu=cortex-m0plus \
	-march=armv6-m \
	-mthumb \
	-mfloat-abi=soft \
	-std=c11 \
	-ffunction-sections \
	-fdata-sections \
	-g3 \
	-gdwarf-4 \
	-Wall \
	-MMD \
	-MP

LFLAGS := \
	-nostartfiles \
	-T$(GENERATED_LIBS) \
	-T$(LINKER_SCRIPT) \
	"-Wl,-Map,$(MAP_FILE)" \
	"-L$(MSPM0_SDK_ROOT)/source" \
	-mcpu=cortex-m0plus \
	-march=armv6-m \
	-mthumb \
	-mfloat-abi=soft \
	-static \
	-Wl,--gc-sections \
	-Wl,--print-memory-usage \
	--specs=nano.specs \
	--specs=nosys.specs \
	-Wl,--start-group \
	-lc \
	-lm \
	-lgcc \
	-Wl,--end-group

.PHONY: all syscfg clean size

all: $(OUTPUT) $(HEX_FILE) $(BIN_FILE)

syscfg: $(SYSCONFIG_OUTPUTS)

size: $(OUTPUT)
	@ $(SIZE) "$(OUTPUT)"

$(BUILD_DIR) $(OBJECT_DIR) $(SYSCONFIG_DIR):
	@ powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force -Path '$@' | Out-Null"

$(SYSCONFIG_OUTPUTS) &: $(SYSCONFIG_FILE) | $(SYSCONFIG_DIR)
	@ echo Generating SysConfig files for GCC...
	@ $(SYSCONFIG_CLI) --compiler gcc --product "$(PRODUCT_JSON)" --output "$(SYSCONFIG_DIR)" "$(SYSCONFIG_FILE)"

$(OBJECT_DIR)/%.o: $(SOURCE_DIR)/%.c $(SYSCONFIG_HEADER) Makefile | $(OBJECT_DIR)
	@ echo Building $@
	@ powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force -Path '$(@D)' | Out-Null"
	@ $(CC) $(CFLAGS) -MF "$(@:.o=.d)" -c "$<" -o "$@"

$(SYSCONFIG_OBJECT): $(SYSCONFIG_SOURCE) $(SYSCONFIG_HEADER) Makefile | $(OBJECT_DIR)
	@ echo Building $@
	@ $(CC) $(CFLAGS) -MF "$(@:.o=.d)" -c "$(SYSCONFIG_SOURCE)" -o "$@"

$(STARTUP_OBJECT): $(STARTUP_SOURCE) $(SYSCONFIG_HEADER) Makefile | $(OBJECT_DIR)
	@ echo Building $@
	@ $(CC) $(CFLAGS) -MF "$(@:.o=.d)" -c "$(STARTUP_SOURCE)" -o "$@"

$(OUTPUT): $(OBJECTS) $(LINKER_SCRIPT) $(GENERATED_LIBS) | $(BUILD_DIR)
	@ echo Linking $@
	@ $(CC) $(OBJECTS) $(LFLAGS) -o "$@"
	@ $(SIZE) "$@"

$(HEX_FILE): $(OUTPUT)
	@ echo Generating $@
	@ $(OBJCOPY) -O ihex "$<" "$@"

$(BIN_FILE): $(OUTPUT)
	@ echo Generating $@
	@ $(OBJCOPY) -O binary "$<" "$@"

clean:
	@ powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools/clean.ps1" -BuildDir "$(BUILD_DIR)"

-include $(DEPENDENCIES)
