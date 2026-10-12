# Example: Running the MobileNet CNN (Coral NPU) — snapshot

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-09-30  
**Project**: AIVHAI  
**Issue**: [#119](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/119)  
**Source**: https://developers.google.com/coral/guides/software/run-mobilenet, last updated 2026-04-08; register entry `Google-26b` in [`bibliography.md`](../bibliography.md)  
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

# Example: Running the MobileNet CNN  Stay organized with collections   Save and categorize content based on your preferences. 

![Spark icon](/_static/images/icons/spark.svg)

## Page Summary

outlined_flag

- This page demonstrates compiling and running a TensorFlow Lite ML model on Coral NPU's scalar core and vector engine using scripted examples.

- The MobileNet V1 model, used for computer vision tasks, is executed using reference kernels from TensorFlow Lite Micro on intermediate layers.

- The process uses the CoreMini AXI high-memory simulator with real inputs and outputs, reporting simulation metrics like execution cycle count.

- Prerequisites include working in the Google Coral NPU GitHub repository and completing specific software and programming tutorials.

- Running the model on the vector execution engine demonstrates optimization and performance comparison to the scalar core example.

The scripted example described here lets you compile and run a LiteRT (TensorFlow Lite) ML model on Coral NPU's simulator. The model executed is MobileNet V1, a convolutional neural network (CNN) designed for image classification, object detection, and other computer vision tasks.

`npusim_run_mobilenet.py` is the host Python script used to run the process.

This page explains the software plumbing and mechanics of how `npusim_run_mobilenet.py` executes and interacts with the compiled C++ binary (`run_full_mobilenet_v1.cc`), using the Coral NPU Python simulator bindings.

## Prerequisites

This example assumes you are working in the Google Coral NPU repository on [GitHub](https://github.com/google-coral/coralnpu).

- Be sure to complete the preliminary steps described in [Software prerequisites and system setup](/coral/guides/software/prerequisites).
- Complete the [Simple programming tutorial](/coral/guides/software/programming).
- Follow the edge AI tutorial [here](https://ai.google.dev/edge/litert/microcontrollers/get_started) to learn about running an inference on microcontrollers.

## Overview

Simulating a LiteRT Micro model such as MobileNet typically requires two software components:

- **Host Python script** (`npusim_run_mobilenet.py`): Controls the Coral NPU simulator, injects inputs, runs the simulation, and extracts outputs.

- **Device C++ binary** (`run_full_mobilenet_v1.cc`): The C++ code sets up the LiteRT (TensorFlow Lite) interpreter to run inference. Building the target with the **coralnpu_v2_binary** Bazel rule packages it to run as an executable on the simulated Coral NPU processor.

## Run the simulation

To run the simulation with the updated Python script, run this Bazel target from the GitHub repository root:\

`bazel run tests/npusim_examples:npusim_run_mobilenet`

## Software flow summary

1.  **Compile**: `run_full_mobilenet_v1.cc` yields an `.elf` file containing non-mangled symbols at static memory addresses.
2.  **Locate**: Python `npusim` parses the `.elf` to find the exact addresses of `inference_input` and `inference_output`.
3.  **Write**: Python writes mock input data into the `inference_input` address pointer.
4.  **Run**: Python invokes the simulator. The C++ code copies `inference_input` to the model, calculates, and copies results to `inference_output`.
5.  **Read**: Simulation finishes. Python reaches into the `inference_output` address pointer to verify the results.

For details about each step, continue reading below.

## C++ device code for MobileNet

The `run_full_mobilenet_v1.cc` C++ code handles the actual inference pipeline. To communicate with the Python host, it exposes specific memory buffers as global variables.

### Memory sections and symbols

We define global arrays placed in specific memory sections (`.data` and `.extdata`) using GCC compiler `__attribute__` pragmas:

``` devsite-click-to-copy
extern "C" {
// The tensor arena for TFLite Micro working memory
constexpr size_t kTensorArenaSize = 4 * 1024 * 1024; // 4MB
uint8_t tensor_arena[kTensorArenaSize] __attribute__((section(".extdata"), aligned(16)));

// Buffers the Python script will read/write
int8_t inference_status = -1;
uint8_t inference_input[224 * 224 * 3] __attribute__((section(".data"), aligned(16)));
int8_t inference_output[5] __attribute__((section(".data"), aligned(16)));
}
```

By placing these inside `extern "C"`, we prevent C++ name mangling, allowing the Python script to easily look up their addresses in the compiled ELF binary by name (for example, `"inference_input"`).

### Inference execution

Inside `main()`, the script uses `memcpy` to bridge the exposed symbols and the internal LiteRT (TFLM) interpreter tensors:

1.  **Input**: `memcpy` copies data from `inference_input` (which Python populated) into the TFLM input tensor.
2.  **Invoke**: The interpreter runs the model.
3.  **Output**: `memcpy` copies data from the TFLM output tensor to `inference_output` , where Python will read it.

Note that `printf` is supported by semi-hosting via HTIF (Host Target Interface), which adds some overhead and impacts performance during simulation. It's recommended that you limit outputs during full performance profiling.

## Python host script

The `npusim_run_mobilenet.py` script uses `CoralNPUV2Simulator` to launch the ELF binary and interacts with the C++ symbols via memory manipulation.

### Simulator initialization and ELF loading

``` devsite-click-to-copy
npu_sim = CoralNPUV2Simulator(highmem_ld=True, exit_on_ebreak=True)
r = runfiles.Create()
elf_file = r.Rlocation('coralnpu_hw/tests/npusim_examples/run_full_mobilenet_v1_binary.elf')
```

The script uses Bazel's `runfiles` utility to locate the compiled `.elf` binary regardless of the host environment.

### Symbol resolution

To communicate with the C++ symbols, Python must find their specific memory addresses:

``` devsite-click-to-copy
entry_point, symbol_map = npu_sim.get_elf_entry_and_symbol(
    elf_file,
    ['inference_status', 'inference_input', 'inference_output']
)
```

`get_elf_entry_and_symbol` parses the ELF file and returns a dictionary (`symbol_map`) mapping strings like `'inference_input'` to their internal 32-bit RISC-V memory addresses.

### Injecting inputs

Before starting the simulator, the script populates the input buffer:

``` devsite-click-to-copy
if symbol_map.get('inference_input'):
    input_data = np.random.randint(-128, 127, size=(224 * 224 * 3,), dtype=np.int8)
    npu_sim.write_memory(symbol_map['inference_input'], input_data)
```

This directly overwrites the bytes at the `inference_input` pointer in the simulator's memory space.

### Execution and output extraction

``` devsite-click-to-copy
npu_sim.run()
npu_sim.wait()
```

The simulator runs until the C++ application exits or hits a breakpoint.

Once complete, the host script reads the output array directly from memory:

``` devsite-click-to-copy
if symbol_map.get('inference_output'):
    output_data = npu_sim.read_memory(symbol_map['inference_output'], 5)
    output_data = np.array(output_data, dtype=np.int8)
```

Finally, `npu_sim.read_memory` is used to check the final `inference_status` value to ensure that execution succeeded.

\

------------------------------------------------------------------------

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
