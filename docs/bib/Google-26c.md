# Bare-metal programming on Coral NPU — snapshot

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-09-30  
**Project**: AIVHAI  
**Issue**: [#119](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/119)  
**Source**: https://developers.google.com/coral/guides/software/bare-metal-prog, last updated 2026-02-12; register entry `Google-26c` in [`bibliography.md`](../bibliography.md)  
**Method**: the page's article body, converted by pandoc 3.9 (`-f html -t gfm-raw_html`), unedited  
**Redistribute**: yes  

---

> **This is not the document.**  It is a snapshot of a web document, kept so that people and agents can search and read the text at the version cited.  Links, images, and navigation may be broken.  Where this text and the source disagree, the source at the pinned version is authoritative.  Copyright and licence are the original's: CC-BY-4.0 for the text and Apache-2.0 for code samples (page footer).

- [Home](https://developers.google.com/)

- 

  [Products](https://developers.google.com/products)

- 

  [Coral](https://developers.google.com/coral)

- 

  [Guides](https://developers.google.com/coral/guides/intro-platform)

# Bare-metal programming on Coral NPU  Stay organized with collections   Save and categorize content based on your preferences. 

Coral NPU is fundamentally a 32-bit RISC-V microcontroller core. It is a [bare-metal](https://en.wikipedia.org/wiki/Bare_machine) CPU designed for a ["run-to-completion"](https://en.wikipedia.org/wiki/Run-to-completion_scheduling) programming model, meaning it doesn't require any operating system or frequent interrupts.

Some amount of bare-metal programming is thus required for Coral NPU. This involves writing code that interacts directly with the hardware without an intervening operating system, typically for tasks like hardware bring-up, deeply embedded firmware, or [RTOS](https://en.wikipedia.org/wiki/Real-time_operating_system) porting. The code is usually written in C, C++, or RISC-V assembly language.

Bare-metal coding involves the following concepts:

- **No operating system**: You are responsible for all hardware management such as initializing the CPU, memory, and peripherals. There is no standard library to rely on unless you use a C runtime library.

- **Compiler toolchain**: If you are coding in C/C++, you need a RISC-V cross-compiler, such as the one from the [RISC-V GNU toolchain project](https://github.com/riscv-collab/riscv-gnu-toolchain). The compiler must incorporate an assembler to generate microcontroller opcodes (binary).

  *Note that if you are just starting to work with Coral NPU, you may want to consider using* [Google's Coral compiler toolchain](https://storage.googleapis.com/shodan-public-artifacts/toolchain_kelvin_tar_files/toolchain_kelvin_v2-2025-09-11.tar.gz) which has been tested successfully for building good binaries. This toolchain uses the Bazel build tool. Details about this custom toolchain can be found [here](https://codewiki.google/github.com/google-coral/coralnpu#risc-v-toolchain-and-runtime-environment) in the Google Gemini GitHub code wiki.

- **Linker script**: A custom linker script is crucial for defining the memory map of the target hardware, specifying where the code and data sections are placed in memory. This script dictates how the program is loaded into ITCM memory and executed by Coral NPU. Coral NPU's memory map is specified [here](/coral/guides/hardware/integration#coral_npu_memory_map).

- **Startup code**: The program must begin execution with a startup or bootstrap routine, sometimes written in assembly, that performs initial setup, initializes registers, copies initialized data, sets up the stack, and then starts execution at a particular memory address.

In a simple microcontroller like Coral NPU, this is all the low-level software ultimately consists of — a binary blob of RISC-V instructions/opcodes that must be preloaded into Coral's ITCM memory.

## Basic requirements for booting Coral NPU

There are two control/status registers that you must load to start the Coral NPU core: `RESET_CONTROL` and `PC_START` (see [Coral NPU custom CSRs](/coral/guides/hardware/architecture#coral_npu_custom_csrs)).

When the core is released from reset and the clock enabled (in RESET_CONTROL), it begins executing instructions in ITCM memory from the address in PC_START (which is 0x00 by default). This booting sequence is described [here](/coral/guides/hardware/integration#booting_coral_npu).

You need to have some type of bootstrap/bootloader program to accomplish these two basic tasks: load ITCM/DTCM memory and set the PC_START register to the desired ITCM starting address.

ELF files are usually used to provide the initial state for a processor's memory. ELF is a binary file format containing instructions and potentially some other data, organized in sections. Conceptually, an ELF file is simply a key-value map where each key is the starting address of a section, and the value contains the bytes that need to be loaded into memory at that address.

Your bootstrap program must do the following:

1.  Read the input ELF file and extract loadable sections.
2.  Copy the sections (bytes) into the specified addresses in Coral's ITCM and DTCM. You can use the C function `memcpy()` for this purpose, or whatever equivalent function is available in your system. `memcpy()` is a standard library function used to copy a specified number of bytes from a source memory location to a destination memory location. It is declared in the `<string.h>` header file.
3.  Load Coral NPU's program counter in PC_START, then release the core's reset and enable the core clock in RESET_CONTROL. See [Booting Coral NPU](/coral/guides/hardware/integration#booting_coral_npu).

As an example, the [test utility code file `elf.cc`](https://github.com/google-coral/coralnpu/blob/main/tests/verilator_sim/elf.cc) (in GitHub) contains a C++ function that accomplishes steps 1 and 2:

### Sample code

``` devsite-click-to-copy
uint32_t LoadElf(uint8_t* data, CopyFn copy_fn) {
    const Elf32_Ehdr* elf_header = reinterpret_cast<Elf32_Ehdr*>(data);
    for (int i = 0; i < elf_header->e_phnum; ++i) {
        const Elf32_Phdr* program_header = reinterpret_cast<Elf32_Phdr*>(
          data + elf_header->e_phoff + sizeof(Elf32_Phdr) * i);
        if (program_header->p_type != PT_LOAD) {
          continue;
        }
        if (program_header->p_filesz == 0) {
          continue;
        }
        copy_fn(reinterpret_cast<void*>(program_header->p_paddr),
          reinterpret_cast<void*>(data + program_header->p_offset),
          program_header->p_filesz);
  }
  return elf_header->e_entry;
}
```

The Coral NPU GitHub repository also includes two other code files that demonstrate similar functionality:

- ELF loading in the testbench: [core_mini_axi_tb.cc](https://github.com/google-coral/coralnpu/blob/main/tests/verilator_sim/coralnpu/core_mini_axi_tb.cc#L288)
- ELF loading from a Python environment (in an SoC simulation): [loader.py](https://github.com/google-coral/coralnpu/blob/main/utils/coralnpu_soc_loader/loader.py#L121)

You can find more details about these Coral NPU utilities in the [Google Gemini GitHub code wiki](https://codewiki.google/github.com/google-coral/coralnpu).

## Bootstrap/startup example

The Coral NPU GitHub repository includes two utility programs `loader.py` and `run_simulation.py` in the directory `https://github.com/google-coral/coralnpu/tree/main/utils/coralnpu_soc_loader/`. The image below shows example shell output when `run_simulation.py` is executed with an input ELF file. `run_simulation.py` launches the Coral NPU simulator and the ELF loader as subprocesses.

``` devsite-click-to-copy
bazel build -c dbg //tests/cocotb:loop.elf
cp -f bazel-out/k8-dbg-ST-dd8dc713f32d/bin/tests/cocotb/loop.elf /tmp
bazel run //utils/coralnpu_soc_loader:run_simulation -- --elf_file /tmp/loop.elf --run_time 10
```

``` devsite-disable-click-to-copy
INFO: Running command line: bazel-bin/utils/coralnpu_soc_loader/run_simulation --elf_file /tmp/loop.elf --run_time 10
WARNING:root:RUNNER: Found free TCP port: 55377
WARNING:root:RUNNER: Starting simulation: /usr/local/google/home/atv/.cache/bazel/_bazel_atv/18d9e8fef5a02c2aa66221c88cabdc0a/execroot/coralnpu_hw/bazel-out/k8-fastbuild/bin/fpga/Vchip_verilator
WARNING:root:RUNNER: Waiting for simulation to be ready...
WARNING:root:[SIM] Simulation of CoralNPU SoC
WARNING:root:[SIM] ======================
WARNING:root:[SIM]
WARNING:root:[SIM] Tracing can be toggled by sending SIGUSR1 to this process:
WARNING:root:[SIM] $ kill -USR1 1154432
WARNING:root:[SIM] No UARTDPI_LOG_uart0 plusarg found.
WARNING:root:[SIM]
WARNING:root:[SIM] UART: Created /dev/pts/11 for uart0. Connect to it with any terminal program, e.g.
WARNING:root:[SIM] $ screen /dev/pts/11
WARNING:root:[SIM] DPI: Server listening on port 55377
WARNING:root:RUNNER: Simulation is ready.
WARNING:root:RUNNER: Starting ELF loader: /usr/local/google/home/atv/.cache/bazel/_bazel_atv/18d9e8fef5a02c2aa66221c88cabdc0a/execroot/coralnpu_hw/bazel-out/k8-fastbuild/bin/utils/coralnpu_soc_loader/loader
WARNING:root:[SIM] UART: Additionally writing all UART output to 'uart0.log'.
WARNING:root:[SIM] No UARTDPI_LOG_uart1 plusarg found.
WARNING:root:[SIM]
WARNING:root:[SIM] UART: Created /dev/pts/12 for uart1. Connect to it with any terminal program, e.g.
WARNING:root:[SIM] $ screen /dev/pts/12
WARNING:root:[SIM] UART: Additionally writing all UART output to 'uart1.log'.
WARNING:root:[SIM]
WARNING:root:[SIM] JTAG: Virtual JTAG interface jtag0 is listening on port 44853. Use
WARNING:root:[SIM] OpenOCD and the following configuration to connect:
WARNING:root:[SIM] adapter driver remote_bitbang
WARNING:root:[SIM] remote_bitbang host localhost
WARNING:root:[SIM] remote_bitbang port 44853
WARNING:root:[SIM]
WARNING:root:[SIM] Simulation running, end by pressing CTRL-c.
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Sending initial idle clocks to flush reset...
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Waiting for SPI bridge to be ready...
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: SPI bridge is ready.
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Opening ELF file: /tmp/loop.elf
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Loading segment to address 0x00000000, size 16 bytes
WARNING:root:[LOADER_ERR] WARNING:root:  ... wrote 16/16 bytes
WARNING:root:[LOADER_ERR] WARNING:root:  ... wrote 16/16 bytes
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Loading segment to address 0x00010000, size 0 bytes
WARNING:root:[LOADER_ERR] WARNING:root:  ... wrote 0/0 bytes
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Binary loaded successfully.
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Programming start PC to 0x00000000
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Releasing clock gate...
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Releasing reset...
WARNING:root:[LOADER_ERR] WARNING:root:LOADER: Execution started.
WARNING:root:[LOADER] SPI_DRIVER: Connecting to localhost:55377...
WARNING:root:[LOADER] SPI_DRIVER: Connected.
WARNING:root:[LOADER] SPI_DRIVER: Closing socket.
WARNING:root:RUNNER: Loader finished. Running simulation for 10 seconds...
WARNING:root:RUNNER: Sending SIGINT to simulator for graceful shutdown...
WARNING:root:[SIM] Received stop request, shutting down simulation.
WARNING:root:[SIM]
WARNING:root:[SIM] Simulation statistics
WARNING:root:[SIM] =====================
WARNING:root:[SIM] Executed cycles:  260219
WARNING:root:[SIM] Wallclock time:   10.916 s
WARNING:root:[SIM] Simulation speed: 23838.3 cycles/s (23.8383 kHz)
WARNING:root:RUNNER: Simulation finished.
WARNING:root:RUNNER: All processes terminated.
WARNING:root:RUNNER: Simulation completed successfully.
```

## Using the C runtime library

Some of the bootstrapping tasks needed on Coral NPU, for example default stack setup, can be handled by using a C runtime library. On Linux and bare-metal systems, the most commonly used library is the GNU C Library (glibc), which also incorporates POSIX-specific functions.

A C runtime library is a collection of low-level routines and startup code linked into a C program to provide the necessary environment for it to run on a specific platform. The library has two primary purposes:

- Program startup and termination: essential glue code that executes before the program's `main()` function is called.

  - Initializing registers and the stack
  - Processing command-line arguments (`argc`, `argv`) and environment variables
  - Calling the `main()` function and then handling its return value to pass back the exit status

- Standard library implementation for functions declared in the C standard library header files (for example, `<string.h>`, `<stdio.h>`, `<stdlib.h>`, `<math.h>`). These functions include:

  - Input/output: `printf()`, `scanf()`, `fopen()`, etc.
  - Memory management: `malloc()`, `free()`, `memcpy()`, etc.
  - String manipulation: `strlen()`, `strcpy()`, etc.
  - Mathematical operations: `sin()`, `sqrt()`, etc.
  - Other services: process control such as `exit()`, `abort()`

With static linking, the libraries required must be compiled, assembled, and linked with your C program — the linker copies the necessary code directly into the final executable file.

Google's toolchain for Coral NPU implements some customizations to the C runtime library that you may find useful; refer to the [Google Gemini GitHub code wiki](https://codewiki.google/github.com/google-coral/coralnpu#risc-v-toolchain-and-runtime-environment-c-run-time-crt-library-and-newlib-integration) for details.

\

------------------------------------------------------------------------

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
