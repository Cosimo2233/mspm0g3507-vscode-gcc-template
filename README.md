# MSPM0G3507 VS Code + Arm GCC 开发模板

当前 SysConfig 目标为立创·地猛星使用的 MSPM0G3507 48Pin `LQFP-48(PT)` 封装。

这是一套不依赖 CCS 工程管理的 MSPM0G3507 通用工程模板，适用于 Windows 和 VS Code。

它提供：

- Microsoft C/C++ 代码补全、跳转和错误提示
- SysConfig 图形化配置与自动代码生成
- Arm GNU Toolchain 编译和链接
- 自动生成 ELF、HEX、BIN 和 map 文件
- DAPLink + OpenOCD 编译、烧录和校验
- DAPLink + OpenOCD + GDB 断点调试
- J-Link 和 XDS110/DSLite 备用烧录任务
- 独立的 Release 与 Debug 构建目录

原始 SDK 不会被修改。工程可以复制到任意目录，只需根据新电脑的安装位置修改工具路径。

## 1. 工程目录

```text
mspm0g3507-vscode-gcc-template/
├─ .vscode/
│  ├─ c_cpp_properties.json   GCC 代码补全配置
│  ├─ extensions.json         推荐扩展
│  ├─ launch.json             DAPLink 调试配置
│  ├─ settings.json           工作区设置
│  └─ tasks.json              编译、清理和烧录任务
├─ config/
│  └─ app.syscfg              SysConfig 工程配置
├─ include/                   用户头文件
├─ src/
│  └─ main.c                  示例主程序
├─ tools/
│  ├─ clean.ps1               安全清理 build 目录
│  ├─ flash-openocd.ps1       DAPLink 烧录
│  ├─ flash-jlink.ps1         J-Link 烧录
│  ├─ flash-xds110.ps1        XDS110/DSLite 烧录
│  └─ mspm0g3507_xds110.ccxml XDS110 目标配置
├─ Makefile                   GCC 构建入口
└─ README.md
```

`build/` 由构建系统自动产生，不属于源代码，已被 `.gitignore` 忽略。

## 2. 当前使用的工具

| 工具 | 当前路径 | 用途 |
| --- | --- | --- |
| MSPM0 SDK 2.04.00.06 | `D:/ti/mspm0_sdk_2_04_00_06` | DriverLib、CMSIS 和设备文件 |
| Arm GNU Toolchain 14.3.1 | `D:/stm32CubeMX/STM32CubeCLT_1.21.0/GNU-tools-for-STM32` | GCC、GDB、objcopy 和 size |
| GNU Make | `D:/ti/ccs/utils/bin/gmake.exe` | 执行 Makefile |
| SysConfig 1.23 | `D:/ti/SYSCONFIG` | 生成初始化代码和链接配置 |
| OpenOCD b56339c | `D:/ti/openocd-b56339c` | DAPLink 烧录和调试服务器 |
| DSLite | `D:/ti/ccs/ccs_base/DebugServer/bin/DSLite.exe` | XDS110 备用烧录 |

本机的 GCC 来自 STM32CubeCLT，但它是标准的 `arm-none-eabi-gcc`，可以用于 Cortex-M0+ 和 MSPM0。也可以换成 Arm 官方 GNU Toolchain，只需修改本节后面列出的路径。

### 2.1 新电脑从零配置环境（重点）

本模板可以放在任意英文路径。若想克隆后直接构建，可以复现当前目录布局：

```text
D:\ti\mspm0_sdk_2_04_00_06
D:\ti\ccs
D:\ti\SYSCONFIG
D:\ti\openocd-b56339c
D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32
```

本机当前工程位于：

```text
D:\workspace\mspm0g3507-vscode-gcc-template
```

工程不必放进 SDK，移动或克隆到其他英文目录不会影响 `src/`、`include/`、`config/` 和 `build/` 的相对路径。

#### 第一步：安装 VS Code 和扩展

安装 64 位 VS Code，然后安装：

| 扩展 | 扩展 ID | 用途 |
| --- | --- | --- |
| Microsoft C/C++ | `ms-vscode.cpptools` | GCC 补全、跳转和错误提示 |
| Cortex-Debug | `marus25.cortex-debug` | OpenOCD + GDB 调试 |
| TI Embedded Development | `ti-development-tools.ti-embedded-development` | MSPM0 设备、SVD 和 TI 工具支持 |

PowerShell 安装命令：

```powershell
code --install-extension ms-vscode.cpptools
code --install-extension marus25.cortex-debug
code --install-extension ti-development-tools.ti-embedded-development
```

安装后重启 VS Code，并使用“文件 → 打开文件夹”打开整个模板目录，不要只打开 `main.c`。

#### 第二步：安装 MSPM0 SDK 2.04.00.06

从 [TI MSPM0 SDK 官方页面](https://www.ti.com/tool/MSPM0-SDK) 获取与模板匹配的 SDK，推荐目录：

```text
D:\ti\mspm0_sdk_2_04_00_06
```

确认：

```text
D:\ti\mspm0_sdk_2_04_00_06\.metadata\product.json
D:\ti\mspm0_sdk_2_04_00_06\source\ti\driverlib\driverlib.h
D:\ti\mspm0_sdk_2_04_00_06\source\ti\devices\msp\m0p\startup_system_files\gcc\startup_mspm0g350x_gcc.c
```

`config/app.syscfg` 当前声明 `mspm0_sdk@2.04.00.06`。使用新版 SDK 时，应在新版 SysConfig 中迁移并保存配置，再验证 48Pin `LQFP-48(PT)` 封装、PA14 LED、时钟和生成的链接脚本。

#### 第三步：安装 Arm GCC

当前已验证的编译器是：

```text
arm-none-eabi-gcc 14.3.1
D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32
```

它由 STM32CubeCLT 提供，但本工程只使用其中的标准 GNU 工具，不依赖 STM32 库。新电脑有两种选择：

1. 安装相同版本的 STM32CubeCLT，保持现有路径，工程无需修改。
2. 从 [Arm GNU Toolchain 官方页面](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) 安装 Windows 的 AArch32 bare-metal `arm-none-eabi` 工具链，然后修改 `GCC_ARM_ROOT` 和 VS Code 路径。

模板已经用 GCC 14.3.1 验证。若追求可复现构建，优先使用相同主版本；换用更新的 GCC 后，应重新检查警告、固件尺寸、链接 map 和硬件运行结果。

GCC 根目录下必须存在：

```text
bin\arm-none-eabi-gcc.exe
bin\arm-none-eabi-gdb.exe
bin\arm-none-eabi-objcopy.exe
bin\arm-none-eabi-size.exe
```

验证：

```powershell
& 'D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32\bin\arm-none-eabi-gcc.exe' --version
& 'D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32\bin\arm-none-eabi-gdb.exe' --version
```

#### 第四步：安装 GNU Make 4.3 或更高版本

Makefile 使用了 GNU Make 的 grouped target 语法 `&:`，因此不要使用 Microsoft `nmake`，并建议 GNU Make 4.3 或更高版本。当前模板使用 CCS 自带的：

```text
D:\ti\ccs\utils\bin\gmake.exe
```

可以从 [TI Code Composer Studio](https://www.ti.com/tool/CCSTUDIO) 获得该工具。GCC 编译本身不依赖 CCS，但安装 CCS 还会提供 XDS110 所需 DSLite。若使用其他 GNU Make，请同步修改 `.vscode/tasks.json` 中所有 `command`。

验证：

```powershell
& 'D:\ti\ccs\utils\bin\gmake.exe' --version
```

#### 第五步：安装独立 SysConfig

从 [TI SysConfig 官方页面](https://www.ti.com/tool/SYSCONFIG) 安装独立版，推荐目录：

```text
D:\ti\SYSCONFIG
```

确认并验证：

```powershell
Test-Path 'D:\ti\SYSCONFIG\sysconfig_cli.bat'
Test-Path 'D:\ti\SYSCONFIG\sysconfig_gui.bat'
& 'D:\ti\SYSCONFIG\sysconfig_cli.bat' --version
```

当前验证版本为 `1.23.0+4000`。Build 会以 `--compiler gcc` 运行 CLI，生成 GCC 形式的 `device.opt`、`device_linker.lds` 和 `device.lds.genlibs`。

#### 第六步：安装支持 MSPM0 的 OpenOCD

DAPLink 烧录和 F5 调试要求：

```text
D:\ti\openocd-b56339c\bin\openocd.exe
D:\ti\openocd-b56339c\share\openocd\scripts\interface\cmsis-dap.cfg
D:\ti\openocd-b56339c\share\openocd\scripts\target\ti\mspm0.cfg
```

OpenOCD 必须包含 MSPM0 Flash Driver 和 `target/ti/mspm0.cfg`；不能随意替换成只支持常见 STM32/GD32 的旧版 OpenOCD。命令和配置说明见 [OpenOCD 官方文档](https://openocd.org/pages/documentation.html)。

验证：

```powershell
& 'D:\ti\openocd-b56339c\bin\openocd.exe' --version
Test-Path 'D:\ti\openocd-b56339c\share\openocd\scripts\target\ti\mspm0.cfg'
```

地猛星使用 `GND`、`CLK/SWCLK`、`DIO/SWDIO`，建议连接 `RST/NRST`。探针和目标板必须共地。

#### 第七步：配置调试所需的 GDB 和 SVD

GDB 已包含在 GCC 工具链中，`.vscode/launch.json` 的 `gdbPath` 必须指向：

```text
<GCC_ARM_ROOT>\bin\arm-none-eabi-gdb.exe
```

外设寄存器视图使用 TI 扩展提供的 SVD。查找实际文件：

```powershell
Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter MSPM0G350X.svd -File -Recurse
```

如果扩展版本不是 `1.0.2`，把查到的路径写入 `.vscode/launch.json` 的 `svdFile`。SVD 路径错误不会影响编译和烧录，但会影响 F5 调试时的外设寄存器显示。

#### 第八步：可选安装 J-Link 和 XDS110/DSLite

- 只用 DAPLink 可跳过 J-Link。
- J-Link 路径在 `tools/flash-jlink.ps1` 中配置。
- XDS110 的 DSLite 路径在 `tools/flash-xds110.ps1` 中配置。
- 所有烧录后端都接受 GCC 生成的 ELF 格式 `build/firmware.out`。

#### 第九步：工具安装路径不同时修改哪些文件

| 路径类型 | 需要修改的文件 |
| --- | --- |
| SDK、GCC、SysConfig | `Makefile` |
| GNU Make、SysConfig GUI、SDK product.json | `.vscode/tasks.json` |
| GCC 和 SDK 头文件 | `.vscode/c_cpp_properties.json`、`.vscode/settings.json` |
| OpenOCD、GDB、SVD | `.vscode/launch.json` |
| OpenOCD 默认位置 | `tools/flash-openocd.ps1` |
| J-Link 默认位置 | `tools/flash-jlink.ps1` |
| DSLite 默认位置 | `tools/flash-xds110.ps1` |

Makefile 和 JSON 中建议统一使用正斜杠，例如 `D:/tools/arm-gnu-toolchain`。

#### 第十步：在新电脑执行环境自检

如果采用当前默认路径，在 PowerShell 执行：

```powershell
$required = @(
    'D:\ti\mspm0_sdk_2_04_00_06\.metadata\product.json',
    'D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32\bin\arm-none-eabi-gcc.exe',
    'D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32\bin\arm-none-eabi-gdb.exe',
    'D:\stm32CubeMX\STM32CubeCLT_1.21.0\GNU-tools-for-STM32\bin\arm-none-eabi-objcopy.exe',
    'D:\ti\ccs\utils\bin\gmake.exe',
    'D:\ti\SYSCONFIG\sysconfig_cli.bat',
    'D:\ti\SYSCONFIG\sysconfig_gui.bat',
    'D:\ti\openocd-b56339c\bin\openocd.exe',
    'D:\ti\openocd-b56339c\share\openocd\scripts\interface\cmsis-dap.cfg',
    'D:\ti\openocd-b56339c\share\openocd\scripts\target\ti\mspm0.cfg'
)
$required | ForEach-Object {
    [pscustomobject]@{ Exists = Test-Path -LiteralPath $_; Path = $_ }
}
```

全部显示 `Exists=True` 后，在工程根目录执行：

```powershell
& 'D:\ti\ccs\utils\bin\gmake.exe' -f Makefile clean
& 'D:\ti\ccs\utils\bin\gmake.exe' -f Makefile all
& 'D:\ti\ccs\utils\bin\gmake.exe' -f Makefile BUILD_DIR=build/debug OPT_LEVEL=-O0 all
```

成功后应存在：

```text
build\firmware.out
build\firmware.hex
build\firmware.bin
build\firmware.map
build\debug\firmware.out
build\syscfg\ti_msp_dl_config.h
```

`gmake: Nothing to be done for 'all'.` 仅表示无需重复编译，不是错误。

## 3. VS Code 扩展

建议安装：

- Microsoft C/C++：代码补全和错误提示
- Cortex-Debug：DAPLink + GDB 调试
- TI Embedded Development：TI 设备和 SysConfig 相关支持

打开工程后，VS Code 如果提示安装工作区推荐扩展，可以直接接受。

## 4. 第一次打开和编译

必须在 VS Code 中打开整个工程目录，而不是只打开某个 `.c` 文件：

```text
D:\workspace\mspm0g3507-vscode-gcc-template
```

第一次编译：

1. 按 `Ctrl+Shift+B`。
2. 默认执行 `MSPM0 GCC: Build`。
3. Makefile 首先运行 SysConfig。
4. SysConfig 在 `build/syscfg/` 中生成设备配置。
5. GCC 编译用户源码、SysConfig 源码和启动文件。
6. GCC 链接并生成固件。

成功后应看到类似输出：

```text
Generating SysConfig files for GCC...
Building build/obj/main.o
Building build/obj/ti_msp_dl_config.o
Building build/obj/startup_mspm0g350x_gcc.o
Linking build/firmware.out
Generating build/firmware.hex
Generating build/firmware.bin
```

如果显示 `Nothing to be done for 'all'`，表示源码和配置没有变化，现有输出已经是最新版本，不是错误。

## 5. 编写代码

用户 `.c` 文件放入 `src/`，用户头文件放入 `include/`。

Makefile 会自动收集所有 `src/*.c`，添加新源文件后无需手工编辑源文件列表。例如：

```text
src/main.c
src/uart.c
src/control.c
include/uart.h
include/control.h
```

在用户代码中包含 SysConfig 生成的头文件：

```c
#include "ti_msp_dl_config.h"
```

程序入口通常保持如下结构：

```c
int main(void)
{
    SYSCFG_DL_init();

    while (1) {
        /* 用户程序 */
    }
}
```

`SYSCFG_DL_init()` 通常只调用一次。它会初始化 SysConfig 中设置的时钟、GPIO 和外设。

修改 `.c` 或 `.h` 后再次按 `Ctrl+Shift+B`。依赖文件位于 `build/obj/*.d`，Make 只重新编译受影响的文件。

## 6. 使用 SysConfig

打开命令面板：

```text
Ctrl+Shift+P → Tasks: Run Task → MSPM0 GCC: Open SysConfig
```

在 SysConfig 中修改 GPIO、UART、ADC、定时器或系统时钟，然后保存 `config/app.syscfg`。下一次 Build 会自动重新生成：

```text
build/syscfg/ti_msp_dl_config.c
build/syscfg/ti_msp_dl_config.h
build/syscfg/device.opt
build/syscfg/device_linker.lds
build/syscfg/device.lds.genlibs
```

不要直接修改 `build/syscfg/` 中的文件，因为它们会在下次生成或 Clean 时被覆盖。需要持久保存的引脚和外设设置应修改 `config/app.syscfg`。

如果只想生成配置而不编译，可执行任务：

```text
MSPM0 GCC: Generate SysConfig
```

## 7. 构建输出

发布构建位于 `build/`：

| 文件 | 用途 |
| --- | --- |
| `build/firmware.out` | 包含符号的 ELF 固件，供 OpenOCD、J-Link 和 DSLite 使用 |
| `build/firmware.hex` | Intel HEX 固件 |
| `build/firmware.bin` | 纯二进制固件 |
| `build/firmware.map` | 链接映射和符号分布 |
| `build/obj/*.o` | GCC 目标文件 |
| `build/obj/*.d` | 增量构建依赖文件 |

Debug 构建位于 `build/debug/`，不会覆盖发布固件。

Makefile 会在链接结束后显示 FLASH 和 SRAM 使用量。

## 8. Makefile 可覆盖变量

```make
PROJECT_NAME ?= firmware
MSPM0_SDK_ROOT ?= D:/ti/mspm0_sdk_2_04_00_06
GCC_ARM_ROOT ?= D:/stm32CubeMX/STM32CubeCLT_1.21.0/GNU-tools-for-STM32
SYSCONFIG_ROOT ?= D:/ti/SYSCONFIG
BUILD_DIR ?= build
OPT_LEVEL ?= -O2
```

换工具版本时可以修改 Makefile，也可以在命令行临时覆盖：

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile GCC_ARM_ROOT=D:/tools/arm-gnu-toolchain all
```

更换 GCC、SDK 或 SysConfig 路径后，还要同步检查：

- `.vscode/c_cpp_properties.json`
- `.vscode/settings.json`
- `.vscode/tasks.json`
- `.vscode/launch.json`

## 9. 清理工程

执行：

```text
Ctrl+Shift+P → Tasks: Run Task → MSPM0 GCC: Clean
```

清理脚本只允许删除当前工程内部指定的 `build/`，不会删除源码、SDK 或工程根目录。

命令行等价操作：

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile clean
```

## 10. DAPLink 接线

| DAPLink/CMSIS-DAP | MSPM0G3507 |
| --- | --- |
| SWDIO | PA19 |
| SWCLK | PA20 |
| GND | GND |
| nRESET | NRST，建议连接 |
| VTref | 目标板 I/O 电压参考 |

注意：

- 调试器与目标板必须共地。
- 确保目标板已经正确供电。
- 不要让多个电源互相反向供电。
- 同一时间只能有一个程序占用 DAPLink。
- 烧录或调试前关闭其他 OpenOCD、pyOCD、CCS、Keil 等程序。

## 11. 使用 DAPLink 编译并烧录

执行：

```text
Ctrl+Shift+P
→ Tasks: Run Task
→ MSPM0 GCC: Build + Flash (DAPLink/OpenOCD)
```

任务按照以下顺序执行：

```text
GCC Build
    ↓
检查 build/firmware.out
    ↓
OpenOCD 连接 CMSIS-DAP
    ↓
编程、校验、复位并运行
```

构建失败时不会继续烧录。当前 OpenOCD 速度为 1000 kHz，可在 `tools/flash-openocd.ps1` 中调整。

烧录成功时通常能看到 `Programming Finished`、`verified` 或类似成功信息。

## 12. DAPLink 断点调试

工程已配置 `.vscode/launch.json`，不需要先执行烧录任务。

调试步骤：

1. 连接 DAPLink 并给目标板供电。
2. 打开 `src/main.c`。
3. 单击行号左侧设置断点，或按 `F9`。
4. 按 `F5`。
5. 如果要求选择配置，选择 `MSPM0G3507 GCC: Debug with DAPLink`。
6. VS Code 自动执行 `MSPM0 GCC: Build (Debug)`。
7. OpenOCD 下载 `build/debug/firmware.out` 并停在 `main()`。

发布与调试使用不同配置：

| 模式 | 优化等级 | 输出 |
| --- | --- | --- |
| 普通 Build/Flash | `-O2` | `build/firmware.out` |
| F5 Debug | `-O0` | `build/debug/firmware.out` |

因此不需要手工修改 Makefile 的优化等级。`-O0` 可以减少变量显示为 `<optimized out>`、源码行跳动或函数被内联的情况。

调试快捷键：

| 操作 | 快捷键 |
| --- | --- |
| 启动或继续 | `F5` |
| 设置或取消断点 | `F9` |
| 单步跳过 | `F10` |
| 单步进入 | `F11` |
| 单步跳出 | `Shift+F11` |
| 重启调试 | `Ctrl+Shift+F5` |
| 停止调试 | `Shift+F5` |

调试侧栏可以查看局部变量、Watch 表达式、调用栈、CPU 寄存器和内存。外设寄存器显示依赖：

```text
${env:USERPROFILE}/.vscode/extensions/
ti-development-tools.cortex-debug-dp-mspm0-1.0.2/data/MSPM0G350X.svd
```

如果 TI 扩展版本发生变化，请更新 `.vscode/launch.json` 中的 `svdFile`。SVD 路径错误只影响外设寄存器视图，不影响编译和普通烧录。

## 13. 备用烧录方式

工程仍保留两个备用任务：

```text
MSPM0 GCC: Build + Flash (J-Link)
MSPM0 GCC: Build + Flash (XDS110/DSLite)
```

J-Link 使用 SWD 和 `build/firmware.out`。XDS110 调用 CCS 中的 DSLite 和 `tools/mspm0g3507_xds110.ccxml`。两者都先执行 GCC Build，编译失败时不会烧录。

当前断点调试只配置 DAPLink，避免多个调试后端造成选择混乱。

## 14. 命令行使用

在工程根目录执行：

```powershell
# 完整发布构建
D:/ti/ccs/utils/bin/gmake.exe -f Makefile all

# 只生成 SysConfig
D:/ti/ccs/utils/bin/gmake.exe -f Makefile syscfg

# 独立 Debug 构建
D:/ti/ccs/utils/bin/gmake.exe -f Makefile BUILD_DIR=build/debug OPT_LEVEL=-O0 all

# 显示固件大小
D:/ti/ccs/utils/bin/gmake.exe -f Makefile size

# 清理
D:/ti/ccs/utils/bin/gmake.exe -f Makefile clean
```

## 15. 常见问题

### 15.1 找不到 `arm-none-eabi-gcc.exe`

检查 `GCC_ARM_ROOT`，该目录下必须存在：

```text
bin/arm-none-eabi-gcc.exe
bin/arm-none-eabi-gdb.exe
bin/arm-none-eabi-objcopy.exe
bin/arm-none-eabi-size.exe
```

同时更新 VS Code 的 `compilerPath` 和 `gdbPath`。

### 15.2 找不到 `ti_msp_dl_config.h`

先运行 `MSPM0 GCC: Generate SysConfig` 或完整 Build。若编译正常但 VS Code 仍显示红线，执行：

```text
Ctrl+Shift+P → C/C++: Reset IntelliSense Database
```

### 15.3 VS Code 报 problemMatcher 引用无效

本工程没有引用 `$gcc`，而是在 `tasks.json` 中使用内联 GCC 错误匹配器。如果复制任务时重新加入了不存在的 `$gcc` 引用，请删除该引用并保留模板中的 `problemMatcher` 对象。

### 15.4 OpenOCD 找不到 CMSIS-DAP

检查 USB 数据线、设备管理器、目标供电和 DAPLink 固件，并关闭其他可能占用探针的软件。

### 15.5 烧录成功但程序没有运行

检查：

- SysConfig 中 LED 或目标外设的引脚是否正确。
- 修改的是当前工程的 `src/`，而不是 SDK 示例目录。
- 烧录任务使用的是否为最新 `build/firmware.out`。
- NRST、SWDIO、SWCLK 和 GND 是否连接可靠。

### 15.6 断点无法命中

检查：

- F5 前的 `MSPM0 GCC: Build (Debug)` 是否成功。
- 调试文件是否为 `build/debug/firmware.out`。
- 断点所在代码是否确实执行。
- 是否设置了过多硬件断点。
- 是否有其他程序占用 DAPLink。

MSPM0G3507 的硬件断点资源有限，不要同时设置大量断点。

## 16. 上传 GitHub

应提交源码、配置和 VS Code 工程文件：

```text
.vscode/
config/
include/
src/
tools/
Makefile
README.md
.gitignore
.gitattributes
.editorconfig
```

不需要提交 `build/`。其他人克隆仓库后，安装 SDK、GCC、SysConfig 和 OpenOCD，更新本机工具路径，然后执行 Build 即可重新生成全部构建文件。

## 17. 推荐日常流程

```text
编辑 src/*.c 和 include/*.h
    ↓
需要时用 SysConfig 修改外设
    ↓
Ctrl+Shift+B 检查编译
    ↓
运行 MSPM0 GCC: Build + Flash (DAPLink/OpenOCD)
    ↓
需要定位问题时设置断点并按 F5
```

这套模板使用 TI 官方 SDK 和 SysConfig 提供设备支持，使用标准 Arm GCC 完成编译链接，并以 DAPLink + OpenOCD 作为日常烧录和调试通道。
