# The Sail instruction-set semantics specification language — snapshot

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-09-30  
**Project**: AIVHAI  
**Issue**: [#119](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/119)  
**Source**: `doc/manual.html` in [Sigil-Logic/sail](https://github.com/Sigil-Logic/sail) branch `sail2` at commit `5745ea9e5369ab4fc51de6f8b773dd8ebc323357`, rendered from `doc/asciidoc/manual.adoc` as last changed upstream in `35d20365` (2025-02-24); register entry `ArmstrongBauereissCampbellEtAl-25` in [`bibliography.md`](../bibliography.md)  
**Method**: the committed HTML rendering, converted by pandoc 3.9 (`-f html -t gfm-raw_html`), unedited  
**Redistribute**: yes  

---

> **This is not the document.**  It is a snapshot of a web document, kept so that people and agents can search and read the text at the version cited.  Links, images, and navigation may be broken.  Where this text and the source disagree, the source at the pinned version is authoritative.  Copyright and licence are the original's: BSD-2-Clause, reproduced above; `doc/asciidoc/manual.css` is MIT.

## Licence (verbatim from the repository LICENSE at the pinned commit)

```
Sail and the Sail architecture models here, comprising all files and
directories except the ASL-derived Sail code in the aarch64 directory,
the logo in the etc/logo/ directory (by Jean Pichon, under CC0), and
various exceptions detailed in THIRD_PARTY_FILES.md are subject to the
BSD two-clause licence below.

The ASL derived parts of the ARMv8.3 specification in
aarch64/no_vector and aarch64/full are copyright ARM Ltd.

This work was partially supported by EPSRC grant EP/K008528/1
REMS: Rigorous Engineering for Mainstream Systems, an ARM iCASE award,
EPSRC IAA KTF funding, and donations from Arm. This project has
received funding from the European Research Council (ERC) under the
European Union’s Horizon 2020 research and innovation programme (grant
agreement No 789108, ELVER).

This software was developed by SRI International and the University of
Cambridge Computer Laboratory (Department of Computer Science and
Technology) under DARPA/AFRL contracts FA8650-18-C-7809 ("CIFV")
and FA8750-10-C-0237 ("CTSRD").

-----

Sail

Copyright (c) 2013-2025
  Kathyrn Gray
  Shaked Flur
  Stephen Kell
  Gabriel Kerneis
  Robert Norton-Wright
  Christopher Pulte
  Peter Sewell
  Alasdair Armstrong
  Brian Campbell
  Thomas Bauereiss
  Anthony Fox
  Jon French
  Dominic Mulligan
  Stephen Kell
  Mark Wassell
  Alastair Reid (Arm Ltd)

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
```

# The Sail instruction-set semantics specification language

Alasdair Armstrong\
Thomas Bauereiss\
Brian Campbell\
Shaked Flur\
Kathryn E. Gray\
Robert Norton-Wright\
Christopher Pulte\
Peter Sewell\

Table of Contents

- [Introduction](#_introduction)
- [A tutorial RISC-V style example](#_a_tutorial_risc_v_style_example)
- [Usage](#_usage)
  - [Sail options](#_sail_options)
  - [C compilation](#_c_compilation)
  - [SystemVerilog compilation (Experimental)](#_systemverilog_compilation_experimental)
  - [Automatic formatting (Experimental)](#_automatic_formatting_experimental)
  - [Interactive mode](#_interactive_mode)
  - [Other options](#_other_options)
  - [Debug options](#_debug_options)
  - [Passing options via SAIL_FLAGS](#_passing_options_via_sail_flags)
- [The Sail Language](#_the_sail_language)
  - [Functions](#_functions)
  - [Blocks](#_blocks)
  - [The `unit` type](#_the_unit_type)
  - [Numeric types and bits](#_numeric_types_and_bits)
  - [Bitvector literals](#_bitvector_literals)
  - [Vectors](#_vectors)
  - [Accessing and updating vectors](#_accessing_and_updating_vectors)
  - [The `list` type](#_the_list_type)
  - [Tuples](#_tuples)
  - [Strings](#_strings)
  - [User-defined types](#_user_defined_types)
    - [Structs](#_structs)
    - [Enums](#_enums)
    - [Unions](#_unions)
    - [`newtype`](#_newtype)
  - [Type synonyms](#_type_synonyms)
  - [Type kinds](#_type_kinds)
  - [Abstract types](#_abstract_types)
  - [Pattern matching](#_pattern_matching)
    - [Guards](#_guards)
    - [Matching on literals](#_matching_on_literals)
    - [Matching on enumerations](#_matching_on_enumerations)
    - [Matching on tuples](#_matching_on_tuples)
    - [Matching on unions](#_matching_on_unions)
    - [Matching on lists](#_matching_on_lists)
    - [Matching on structs](#_matching_on_structs)
    - [As patterns](#_as_patterns)
    - [Automatic wildcard insertion](#_automatic_wildcard_insertion)
  - [Matching in let and function arguments](#_matching_in_let_and_function_arguments)
  - [Type patterns](#_type_patterns)
  - [Mutable variables](#_mutable_variables)
  - [Assignment and l-values](#_assignment_and_l_values)
  - [Registers](#_registers)
  - [Bitfields](#_bitfields)
  - [Operators](#_operators)
    - [Built-in precedences](#_built_in_precedences)
  - [Ad-hoc overloading](#_ad_hoc_overloading)
  - [Mappings](#_mappings)
  - [Sizeof and constraint](#_sizeof_and_constraint)
  - [Exceptions](#_exceptions)
  - [Scattered definitions](#_scattered_definitions)
  - [Preludes and default environment](#_preludes_and_default_environment)
- [Model Configuration](#_model_configuration)
  - [JSON representation of Sail types](#_json_representation_of_sail_types)
  - [Runtime Configuration with Sail to C](#_runtime_configuration_with_sail_to_c)
  - [Configurable abstract types](#_configurable_abstract_types)
  - [Validating Configurations with JSON Schema](#_validating_configurations_with_json_schema)
- [Modular Sail Specifications](#_modular_sail_specifications)
  - [Modules](#_modules)
  - [Working with Makefiles](#_working_with_makefiles)
  - [Conditional compilation within modules](#_conditional_compilation_within_modules)
  - [Optional and default modules](#_optional_and_default_modules)
- [The Sail Grammar](#_the_sail_grammar)
- [References](#_references)

## Introduction

Sail is a language for expressing the instruction-set architecture (ISA) semantics of processors.

Vendor architecture specification documents typically describe the sequential behaviour of their ISA with a combination of prose, tables, and pseudocode for each instruction.

They vary in how precise that pseudocode is: in some it is just suggestive, while in others it is close to a complete description of the envelope of architecturally allowed behaviour for sequential code.

For x86 \[[1](#Intel61)\], the Intel pseudocode is just suggestive, with embedded prose, while the AMD descriptions \[[2](#AMD_3_21)\] are prose alone. For IBM Power \[[3](#Power3.0B)\], there is detailed pseudocode which has recently become machine-processed \[[4](#Leighton21)\]. For Arm \[[5](#armarmv8)\], there is detailed pseudocode, which has recently become machine-processed \[[6](#Reid16)\]. For MIPS \[[7](#MIPS64-II), [8](#MIPS64-III)\] there is also reasonably detailed pseudocode.

Sail is intended:

- To support precise definition of real-world ISA semantics;

- To be accessible to engineers familiar with existing vendor pseudocodes, with a similar style to the pseudocodes used by ARM and IBM Power (modulo minor syntactic differences);

- To expose the structure needed to combine the sequential ISA semantics with the relaxed-memory concurrency models we have developed;

- To provide an expressive type system that can statically check the bitvector length and indexing computation that arises in these specifications, to detect errors and to support code generation, with type inference to minimise the required type annotations;

- To support execution, for architecturally complete emulation automatically based on the definition;

- To support automatic generation of theorem-prover definitions, for mechanised reasoning about ISA specifications; and

- To be as minimal as possible given the above, to ease the tasks of code generation and theorem-prover definition generation.

A Sail specification will typically define an abstract syntax type/tre (AST) of machine instructions, a decode function that takes binary values to AST values, and an execute function that describes how each of those behaves at runtime, together with whatever auxiliary functions and types are needed.

Given such a specification, the Sail implementation can typecheck it and generate:

- An internal representation of the fully type-annotated definition (a deep embedding of the definition) in a form that can be executed by the Sail interpreter. These are both expressed in Lem \[[9](#Lem-icfp2014), [10](#Lemcode)\], a language of type, function, and relation definitions that can be compiled into OCaml and various theorem provers. The Sail interpreter can also be used to analyse instruction definitions (or partially executed instructions) to determine their potential register and memory footprints.

- A shallow embedding of the definition, also in Lem, that can be executed or converted to theorem-prover code more directly. Currently this is aimed at Isabelle/HOL or HOL4, though the Sail dependent types should support generation of idiomatic Coq definitions (directly rather than via Lem).

- A compiled version of the specification directly into OCaml.

- A more efficient executable version of the specification, compiled into C code.

Sail has been used to develop models of parts of several architectures:

|  |  |  |
|----|----|----|
| Arm-v8 (ASL) | generated from Arm’s v8.5 public ASL spec | [github.com/rems-project/sail-arm/tree/master/arm-v8.5-a](https://github.com/rems-project/sail-arm/tree/master/arm-v8.5-a) |
| Arm-v9 (ASL) | generated from Arm’s v9.3 public ASL spec | [github.com/rems-project/sail-arm/tree/master/arm-v9.3-a](https://github.com/rems-project/sail-arm/tree/master/arm-v9.3-a) |
| RISC-V | hand-written | [github.com/riscv/sail-riscv](https://github.com/riscv/sail-riscv) |
| CHERI-MIPS | hand-written | [github.com/CTSRD-CHERI/sail-cheri-mips](https://github.com/CTSRD-CHERI/sail-cheri-mips) |

The Arm-v8 (ASL) model is based on an automatic translation of Arm’s machine-readable public v8.3 ASL specification ^(\[[1](#_footnotedef_1 "View footnote.")\]). It includes everything in ARM’s specification.

The MIPS model is hand-written based on the MIPS64 manual version 2.5 \[[7](#MIPS64-II), [8](#MIPS64-III)\], but covering only the features in the BERI hardware reference \[[11](#UCAM-CL-TR-868)\], which in turn drew on MIPS4000 and MIPS32 \[[12](#MIPS4000), [13](#MIPS32-I)\].

The CHERI model is based on that and the CHERI ISA reference manual version 5 \[[14](#UCAM-CL-TR-891)\]. These two are both principally by Norton-Wright; they cover all basic user and kernel mode MIPS features sufficient to boot FreeBSD, including a TLB, exceptions and a basic UART for console interaction. ISA extensions such as floating point are not covered. The CHERI model supports either 256-bit capabilities or 128-bit compressed capabilities.

## A tutorial RISC-V style example

We introduce the basic features of Sail via a small example from our RISC-V model that includes just two instructions: add immediate and load double. We start by defining the default order (see [Vectors](#_vectors) for details), and including the Sail prelude:

``` rouge
default Order dec
$include <prelude.sail>
```

The Sail prelude is very minimal, and it is expected that Sail specifications will usually build upon it. Some Sail specifications are derived from pre-existing pseudocode, which already use specific idioms — our Sail Arm specification uses `ZeroExtend` and `SignExtend` mirroring the ASL code, whereas our MIPS and RISC-V specification use `EXTZ` and `EXTS` for the same functions. Therefore for this example we define zero-extension and sign-extension functions as:

``` rouge
val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
function EXTZ(m, v) = sail_zero_extend(v, m)

val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
function EXTS(m, v) = sail_sign_extend(v, m)
```

We now define an integer type synonym `xlen`, which for this example will be equal to 64. Sail supports definitions which are generic over both regular types, and integers (think const generics in C++, but more expressive). We also create a type `xlenbits` for bitvectors of length `xlen`.

``` rouge
type xlen       : Int = 64
type xlen_bytes : Int = 8
type xlenbits         = bits(xlen)
```

For the purpose of this example, we also introduce a type synonym for bitvectors of length 5, which represent registers.

``` rouge
type regbits = bits(5)
```

We now set up some basic architectural state. First creating a register of type `xlenbits` for both the program counter `PC`, and the next program counter, `nextPC`. We define the general purpose registers as a vector of 32 `xlenbits` bitvectors. The `dec` keyword isn’t important in this example, but Sail supports two different numbering schemes for (bit)vectors `inc`, for most significant bit is zero, and `dec` for least significant bit is zero. We then define a getter and setter for the registers, which ensure that the zero register is treated specially (in RISC-V register 0 is always hardcoded to be 0). Finally we overload both the read (`rX`) and write (`wX`) functions as simply `X`. This allows us to write registers as `X(r) = value` and read registers as `value = X(r)`. Sail supports flexible ad-hoc overloading, and has an expressive l-value language in assignments, with the aim of allowing pseudo-code like definitions.

``` rouge

register PC : xlenbits
register nextPC : xlenbits

register Xs : vector(32, dec, xlenbits)

val rX : regbits -> xlenbits
function rX(r) =
  match r {
    0b00000 => EXTZ(0x0),
    _ => Xs[unsigned(r)]
  }

val wX : (regbits, xlenbits) -> unit
function wX(r, v) =
  if r != 0b00000 then {
     Xs[unsigned(r)] = v;
  }

overload X = {rX, wX}
```

We also give a function `MEMr` for reading memory, this function just points at a builtin we have defined elsewhere. The builtin is very general (it allows addresses of multiple bitwidths), so we also derive a simpler `read_mem` function.

``` rouge
val MEMr = impure { lem: "MEMr", coq: "MEMr", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
   (int('m), int('n), bits('m), bits('m)) -> bits(8 * 'n)

val read_mem : forall 'n, 'n >= 0. (xlenbits, int('n)) -> bits(8 * 'n)
function read_mem(addr, width) =
    MEMr(sizeof(xlen), width, EXTZ(0x0), addr)
```

It’s common when defining architecture specifications to break instruction semantics down into separate functions that handle decoding (possibly even in several stages) into custom intermediate datatypes and executing the decoded instructions. However it’s often desirable to group the relevant parts of these functions and datatypes together in one place, as they would usually be found in an architecture reference manual. To support this Sail supports *scattered* definitions. First we give types for the execute and decode functions, as well as the `ast` union.

``` rouge
enum iop = {RISCV_ADDI, RISCV_SLTI, RISCV_SLTIU, RISCV_XORI, RISCV_ORI, RISCV_ANDI}

scattered union ast

val decode : bits(32) -> option(ast)
val execute : ast -> unit
```

Now we provide the clauses for the add-immediate `ast` type, as well as its execute and decode clauses. We can define the decode function by directly pattern matching on the bitvector representing the instruction. Sail supports vector concatenation patterns (`@` is the vector concatenation operator), and uses the types provided (e.g. `bits(12)` and `regbits`) to destructure the vector in the correct way. We use the `EXTS` function that sign-extends its argument.

``` rouge
union clause ast = ITYPE : (bits(12), regbits, regbits, iop)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b000 @ rd : regbits @ 0b0010011
  = Some(ITYPE(imm, rs1, rd, RISCV_ADDI))

function clause execute (ITYPE (imm, rs1, rd, RISCV_ADDI)) = {
  let rs1_val = X(rs1);
  let imm_ext : xlenbits = EXTS(imm);
  let result = rs1_val + imm_ext;
  X(rd) = result
}
```

Now we do the same thing for the load-double instruction:

``` rouge
union clause ast = LOAD : (bits(12), regbits, regbits)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b011 @ rd : regbits @ 0b0000011
  = Some(LOAD(imm, rs1, rd))

function clause execute(LOAD(imm, rs1, rd)) = {
    let addr : xlenbits = X(rs1) + EXTS(imm);
    let result : xlenbits = read_mem(addr, sizeof(xlen_bytes));
    X(rd) = result
}
```

Finally we define the fallthrough case for the decode function. Note that the clauses in a scattered function will be matched in the order they appear in the file.

``` rouge
function clause decode _ = None()
```

## Usage

In its most basic use-case Sail is a command-line tool, analogous to a compiler: one gives it a list of input Sail files; it type-checks them and provides translated output.

To simply typecheck Sail files, one can pass them on the command line with no other options, for example:

``` rouge
sail prelude.sail riscv_types.sail riscv_mem.sail riscv_sys.sail riscv_vmem.sail riscv.sail
```

The sail files passed on the command line are simply treated as if they are one large file concatenated together, although the parser will keep track of locations on a per-file basis for error-reporting. As can be seen, this specification is split into several logical components. `prelude.sail` defines the initial type environment and builtins, `riscv_types.sail` gives type definitions used in the rest of the specification, `riscv_mem.sail` and `riscv_vmem.sail` describe the physical and virtual memory interaction, and then `riscv_sys.sail` and `riscv.sail` implement most of the specification.

One can use also use `$include` directives in Sail source, for example:

``` rouge
$include <library.sail>
$include "file.sail"
```

Here, Sail will look for `library.sail` in the `$SAIL_DIR/lib` directory, where `$SAIL_DIR` is usually the root of the sail repository (or `opam var sail:share` when Sail is installed using opam). It will search for `file.sail` relative to the location of the file containing the `$include`. The space after the `$include` before the filename is mandatory. Sail also supports `$define`, `$ifdef`, and `$ifndef` for basic conditional compilation. These are things that are understood by Sail itself, not a separate preprocessor, and are handled after the AST is parsed.

For more complex projects, a module hierarchy can be defined. See the [Modules](#_modules) section for details.

### Sail options

For backwards compatibility reasons, Sail accepts arguments of the form `-long_opt`, i.e. leading with a single `-` and words separated by `_`. Such an option will be treated the same as `--long-opt`.

For a list of all options, one can call Sail as `sail --help`.

### C compilation

To compile Sail into C, the `-c` option is used, like so:

``` rouge
sail -c FILES 1> out.c
```

The translated C is by default printed to stdout, but one can also use the `-o` option to output to a file, so

``` rouge
sail -c FILES -o out
```

will generate a file called `out.c`. To produce an executable this needs to be compiled and linked with the C files in the `$SAIL_DIR/lib` directory:

``` rouge
gcc out.c $SAIL_DIR/lib/*.c -lgmp -I $SAIL_DIR/lib/ -o out
```

The C output requires the [GMP library](https://gmplib.org/) for arbitrary precision arithmetic.

There are several Sail options that affect the C output:

- `-O` turns on optimisations. The generated C code will be quite slow unless this flag is set.

- `--Oconstant-fold` apply constant folding optimisations.

- `--c-include` Supply additional header files to be included in the generated C.

- `--c-no-main` Do not generate a `main()` function.

### SystemVerilog compilation (Experimental)

[TABLE]

To compile Sail into SystemVerilog, the `--sv` option is used. The `-o` option provides a prefix that is used on the various generated files.

There are several options for the SystemVerilog output:

- `--sv-output-dir` Generate all files in the specified directory

- `--sv-include` Add an include directive to the generated SystemVerilog

- `--sv-verilate` Can be used as either `--sv-verilate run` or `--sv-verilate compile`. If used Sail will automatically invoke [verilator](https://www.veripool.org/verilator/) on the generated SystemVerilog

- `--sv-lines` Output SystemVerilog \`line directives to aid debugging.

- `--sv-int-size` Set the maximum integer size allowed in the specification.

- `--sv-bits-size` Bound the maximum bitvector width on the generated SystemVerilog.

- `--sv-specialize` The `--sv-specialize n` option will perform `n` rounds of specialisation on the Sail code before generating SystemVerilog. This will make bitvectors more monomorphic, but at the cost of code duplication.

The are various other options that control various minutae about the generated SystemVerilog, see `sail --help` for more details.

### Automatic formatting (Experimental)

[TABLE]

Sail supports automatic code formatting similar to tools like `go fmt` or `rustfmt`. This is built into Sail itself, and can be used via the `--fmt` flag. To format a file `my_file.sail`, we would use the command:

``` rouge
sail --fmt my_file.sail
```

Note that Sail does not attempt to type-check files when formatting them, so in this case we do not necessarily have to pass the other files that `my_file.sail` would otherwise require to type-check. However, it is perfectly fine to pass multiple files like so:

``` rouge
sail --fmt file1.sail file2.sail file3.sail
```

The one exception is if a file uses a custom infix operator, then the file that declares that operator must be passed before any file that uses it. So if `my_file.sail` uses an operator declared in `operator.sail` (otherwise it would not be able to parenthesize infix expressions correctly), we would be required to do:

``` rouge
sail --fmt operator.sail my_file.sail
```

This will format both files. If we want to avoid formatting `operator.sail`, we could either use `--fmt-skip`, like so:

``` rouge
sail --fmt-skip operator.sail --fmt operator.sail my_file.sail
```

or the `--fmt-only` option, like so:

``` rouge
sail --fmt-only my_file.sail --fmt operator.sail my_file.sail
```

Both of these options can be passed multiple times if required.

Formatting configuration is done using a JSON configuration file: as:

``` rouge
{
    "fmt": {
        "indent": 4,
        "preserve_structure": false,
        "line_width": 120,
        "ribbon_width": 1.0
    }
}
```

which is passed to sail with the `--config` flag.

The various keys supported under the `"fmt"` key are as follows:

- `indent` The default indentation level

- `preserve_structure` Preserve the structure of the syntax tree as much as possible. Note that the use of this operation is not recommended as it inhibits many formatting options, such as inserting blocks on if statements and loops.

- `line_width` The desired maximum line-width. Note that this is a soft limit, and the line-width can go beyond if there are no possible line break options (e.g. if you have *extremely* long identifiers).

- `ribbon_width` A soft limit on what proportion (between 0.0 and 1.0) of the line should be non-whitespace. A value of 1.0 indicates that the entirity of `line_width` can be taken up by non-whitespace.

If this file is not passed on the command line, Sail will check the `$SAIL_CONFIG` environment variable, and if that is unset it will search for a file named `sail_config.json` in the current working directory, then recursively backwards through parent directories.

### Interactive mode

Sail has a GHCi-style interactive interpreter. This can be used by starting Sail with `sail -i`. Sail will still handle any other command line arguments as per usual. To use Sail files within the interpreter they must be passed on the command line as if they were being compiled normally. One can also pass a list of commands to the interpreter by using the `--is` flag, as

``` rouge
sail --is <file>
```

where `<file>` contains a list of commands. Once inside the interactive mode, a list of available commands can be accessed by typing `:commands`, while `:help <command>` can be used to provide some documentation for each command.

### Other options

Here we summarize most of the other options available for Sail. Debugging options (usually for debugging Sail itself) are indicated by starting with the letter `d`.

- `-v` Print the Sail version.

- `-help` Print a list of options.

- `--no-warn` Turn off warnings.

- `--enum-casts` Allow elements of enumerations to be automatically cast to numbers.

- `--memo-z3` Memoize calls to the Z3 solver. This can greatly improve typechecking times if you are repeatedly typechecking the same specification while developing it.

- `--no-lexp-bounds-check` Turn off bounds checking in the left hand side of assignments. This option only exists for some Sail translated from ASL (as ASL does not do compile-time bounds checking here).

- `--just-check` Force Sail to terminate immediately after typechecking.

- `--require-version`. Check that the Sail version is newer than the specified version, if not Sail will print an error and exit with a non-zero exit code.

### Debug options

These options are mostly used for debugging the Sail compiler itself. They are included as they might be useful for those writing custom Sail plugins. These options are all prefixed with `d`.

- `--dtc-verbose <verbosity>` Make the typechecker print a trace of typing judgements. If the verbosity level is 1, then this should only include fairly readable judgements about checking and inference rules. If verbosity is 2 then it will include a large amount of debugging information. This option can be useful to diagnose tricky type-errors, especially if the error message isn’t very good.

- `--ddump-initial-ast` Write the AST out immediately after parsing and desugaring.

- `--ddump-tc-ast` Write the typechecked AST to stdout after typechecking

- `--ddump-side-effects` Print inferred information about function side effects

- `--ddump-rewrite-ast <prefix>` Write the AST out after each re-writing pass. The output from each pass is placed in a file starting with `prefix`.

- `--dmagic-hash` Allow the `#` symbol in identifiers. It’s currently used as a magic symbol to separate generated identifiers from those the user can write, so this option allows for the output of the various other debugging options to be fed back into Sail. The name comes from the GHC option with the same purpose: [ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/magic_hash.html](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/magic_hash.html)

### Passing options via SAIL_FLAGS

The `SAIL_FLAGS` environment variable can be used to pass additional flags to Sail without passing them directly on the command line. The arguments contained in this variable are separated by spaces (multiple spaces will be treated as a single separator). For more robust splitting of arguments, the `SAIL_ENCODED_FLAGS` environment variable can be used instead. Here, arguments are separated by the ASCII unit separator control character `0x1f`, and are then passed unmodified without any trimming of whitespace. If set the `SAIL_ENCODED_FLAGS` variable will take precedence and the `SAIL_FLAGS` variable will be ignored.

## The Sail Language

### Functions

In Sail, we often define functions in two parts. First we can write the type signature for the function using the `val` keyword, then define the body of the function using the `function` keyword. In this Subsection, we will write our own version of the `replicate_bits` function from the Sail library. This function takes a number `n` and a bitvector, and creates a new bitvector containing that bitvector copied `n` times.

``` rouge
val my_replicate_bits : forall 'n 'm, 'm >= 1 & 'n >= 1.
    (int('n), bits('m)) -> bits('n * 'm)
```

This signature shows how Sail can track the length of bitvectors and the value of integer variables in type signatures, using *type variables*. Type variables are written with a leading 'tick', so `'n` and `'m` are the type variables in the above signature.

[TABLE]

The type `bits('m)` is a bitvector of length `'m`, and `int('n)` is an integer with the value `'n`. The result of this function will therefore be a bitvector of length `'n * 'm`. We can also add *constraints* on these types. Here we require that we are replicating the input bitvector at least once with the `'n >= 1` constraint, and that the input bitvector length is at least one with the `'m >= 1` constraint. Sail will check that all callers of this function are guaranteed to satisfy these constraints.

Sail will also ensure that the output of our function has precisely the length `bits('n * 'm)` for all possible inputs (hence why the keyword uses the mathematical *forall* quantifier).

A potential implementation of this function looks like:

``` rouge
function my_replicate_bits(n, xs) = {
    var ys = zeros(n * length(xs));
    foreach (i from 1 to n) {
        ys = ys << length(xs);
        ys = ys | zero_extend(xs, length(ys))
    };
    ys
}
```

Functions may also have implicit parameters, e.g. we can implement a zero extension function that implicitly picks up its result length from the calling context as follows:

``` rouge
val extz : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function extz(m, xs) = zero_extend(xs, m)
```

Implicit parameters are always integers, and they must appear first before any other parameters in the function type signature. The first argument can then just be omitted when calling the function, like so:

``` rouge
let xs: bits(32) = 0x0000_0000;
let ys: bits(64) = extz(xs);
```

### Blocks

You may have noticed that in the definition of `my_replicate_bits` above, there was no `return` keyword. This is because unlike languages such as C and C++, and more similar to languages like OCaml and Rust, everything in Sail is an *expression* which evaluates to a value. A block in Sail is simply a sequence of expressions surrounded by curly braces `{` and `}`, and separated by semicolons. The value returned by a block is the value returned by the last expression, and likewise the type of a block is determined by its final expression, so `{ A; B; C }`, will evaluate to the value of `C` after evaluating `A` and `B` in order. The expressions other than the final expression in the block must have type `unit`, which is discussed in the following section. Within blocks we can declare immutable variables using `let`, and mutable variables using `var`, for example:

``` rouge
{
    let x : int = 3;
    var y : int = 2;
    y = y + 1;
    x + y
}
```

The above block has type `int` and evaluates to the value `6`.

[TABLE]

### The `unit` type

The simplest type in Sail is the *unit type* `unit`. It is a type with a single member `()`. Rather than have functions that takes zero arguments, we have functions that take a single `unit` argument. Similarly, rather than having functions that return no results, a function with no meaningful return value can return `()`. The `()` notation reflects the fact that the unit type can be thought of as an empty tuple (see [Tuples](#_tuples)).

In Sail `unit` plays a similar role to void in C and C++, except unlike void it is an ordinary type and can appear anywhere and be used in generic functions.

The [wikipedia page for the unit type](https://en.wikipedia.org/wiki/Unit_type), goes into further details on the difference between unit and void.

### Numeric types and bits

Sail has three basic numeric types, `int`, `nat`, and `range`. The type `int` which we have already seen above is an arbitrary precision mathematical integer. Likewise, `nat` is an arbitrary precision natural number. The type `range('n, 'm)` is an inclusive range between type variables `'n` and `'m`. For both `int` and `nat` we can specify a type variable that constrains elements of the type to be equal to the value of that type variable. In other words, the values of type `int('n)` are integers equal to `'n`. So `5 : int(5)` and similarly for any integer constant. These types can often be used interchangeably provided certain constraints are satisfied. For example, `int('n)` is equivalent to `range('n, 'n)` and `range('n, 'm)` can be converted into `int('n)` when `'n == 'm`.

[TABLE]

Note that `bit` isn’t a numeric type (i.e. it’s not `range(0, 1)`). This is intentional, as otherwise it would be possible to write expressions like `(1 : bit) + 5` which would end up being equivalent to `6 : range(5, 6)`. This kind of implicit casting from bits to other numeric types would be highly undesirable. The `bit` type itself is a two-element type with members `bitzero` and `bitone`.

In addition, we can write a numeric type that only contains a fixed set of integers. The type `{32, 64}` is a type that can only contain the values `32` and `64`.

[TABLE]

### Bitvector literals

Bitvector literals in Sail are written as either `0x` followed by a sequence of hexadecimal digits (as in `0x12FE`) or `0b` followed by a sequence of binary digits (as in `0b1010100`). The bit length of a hex literal is always four times the number of hexadecimal digits, and the bit length of binary literal is always the exact number of binary digits. So, `0x12FE` has bit length 16, and `0b1010100` has bit length 7. To ensure bitvector logic in specifications is precisely specified, we do not allow any kind of implicit widening or truncation as might occur in C. To change the length of a bitvector, explicit zero/sign extension and truncation functions must be used. Underscores can be used in bitvector literals to separate groups, where each group is typically 16 bits. For example:

``` rouge
let large_bitvector : bits(64) = 0xFFFF_0000_1234_0000
```

We can make bitvectors as large as we need:

``` rouge
let even_larger_bitvector : bits(192) =
  0xFFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000_ABCD_ABCD_ABCD_ABCD
```

We can also write bitvectors very verbosely using `bitzero` and `bitone`, like:

``` rouge
let v : bits(2) = [bitzero, bitzero]
```

The `@` operator is used to concatenate bitvectors, for example:

``` rouge
let x = 0xFFFF;
let y = 0x0000;
assert(x @ y == 0xFFFF_0000);
```

For historical reasons the `bit` type is not equal to `bits(1)`, and while this does simplify naively mapping the bits type into a (very inefficient!) representation like `bit list` in Isabelle or OCaml, it might be something we reconsider in the future.

Sail allows two different types of bitvector orderings---increasing (`inc`) and decreasing (`dec`). These two orderings are shown for the bitvector 0b10110000 below.

![ordering tikz](ordering-tikz.png)

For increasing (bit)vectors, the 0 index is the most significant bit and the indexing increases towards the least significant bit. Whereas for decreasing (bit)vectors the least significant bit is 0 indexed, and the indexing decreases from the most significant to the least significant bit. For this reason, increasing indexing is sometimes called \`most significant bit is zero' or MSB0, while decreasing indexing is sometimes called \`least significant bit is zero' or LSB0. While this vector ordering makes most sense for bitvectors (it is usually called bit-ordering), in Sail it applies to all vectors. A default ordering can be set using

``` rouge
default Order dec
```

and this should usually be done right at the beginning of a specification. This setting is global, and increasing and decreasing bitvectors can therefore never be mixed within the same specification!

In practice decreasing order is the almost universal standard and only POWER uses increasing order. All currently maintained Sail specifications use decreasing. You may run into issues with increasing bitvectors as the code to support these is effectively never exercised as a result.

### Vectors

Sail has the built-in type `vector`, which is a polymorphic type for fixed-length vectors. For example, we could define a vector `v` of three integers as follows:

``` rouge
let v : vector(3, int) = [3, 2, 1]
```

The first argument of the vector type is a numeric expression representing the length of the vector, and the second is the type of the vector’s elements. As mentioned in the bitvector section, the ordering of bitvectors and vectors is always the same, so:

``` rouge
    let a_generic_vector : vector(3, bit) = [bitzero, bitzero, bitone];
    let a_bitvector : bits(3) = [bitzero, bitzero, bitone]; // 0b001

    assert(a_generic_vector[0] == bitone);
    assert(a_bitvector[0] == bitone)
```

Note that a generic vector of bits and a bitvector are not the same type, despite us being able to write them using the same syntax. This means you cannot write a function that is polymorphic over both generic vectors and bitvectors). This is because we typically want these types to have very different representations in our various Sail backends, and we don’t want to be forced into a compilation strategy that requires monomorphising such functions.

### Accessing and updating vectors

A (bit)vector can be indexed by using the *vector index* notation. So, in the following code:

``` rouge
let v : vector(4, int) = [1, 2, 3, 4]
let a = v[0]
let b = v[3]
```

`a` will be `4`, and `b` will be `1` (we assume `default Order dec` here). By default, Sail will statically check for out of bounds errors, and will raise a type error if it cannot prove that all such vector accesses are valid.

A vector `v` can be sliced using the `v[n .. m]` notation. The indexes are always supplied with the index closest to the MSB being given first, so we would take the bottom 32-bits of a decreasing bitvector `v` as `v[31 .. 0]`, and the upper 32-bits of an increasing bitvector as `v[0 .. 31]`, i.e. the indexing order for decreasing vectors decreases, and the indexing order for increasing vectors increases.

A vector `v` can have an index `index` using `[v with index = expression]`. Similarly, a sub-range of v can be updated using `[v with n .. m = expression]` where the order of the indexes is the same as described above for increasing and decreasing vectors.

### The `list` type

In addition to vectors, Sail also has `list` as a built-in type. For example:

``` rouge
let l : list(int) = [|1, 2, 3|]
```

The cons operator is `::`, so we could equally write:

``` rouge
let l : list(int) = 1 :: 2 :: 3 :: [||]
```

For those unfamiliar the word, 'cons' is derived from Lisp dialects, and has become standard functional programming jargon for such an operator — see [en.wikipedia.org/wiki/Cons](https://en.wikipedia.org/wiki/Cons) for more details.

[TABLE]

### Tuples

Sail has tuple types which represent heterogeneous sequences containing values of different types. A tuple type `(T1, T2, …​)` has values `(x1, x2, …​)` where `x1 : T1`, `x2 : T2` and so on. A tuple must have 2 or more elements. Some examples of tuples would be:

``` rouge
let tuple1 : (string, int) = ("Hello, World!", 3)

let tuple2 : (nat, nat, nat) = (1, 2, 3)
```

Note that while the function type `(A, B) -> C` might look like a function taking a single tuple argument, it is in fact a function taking two arguments. If we wanted to write a function taking a single tuple argument, we would instead write:

``` rouge
val single_tuple_argument : ((int, int)) -> unit

function single_tuple_argument(tuple) = {
  let (x, y) = tuple;
  print_int("x = ", x);
  print_int("y = ", y);
}
```

which would be called as

``` rouge
single_tuple_argument((1, 2))
```

[TABLE]

### Strings

Sail has a `string` type, which is primarily used for error reporting and debugging.

[TABLE]

A Sail string is any sequence of ASCII characters between double quotes. Backslash is used to introduce escape sequences, and the following escape sequences are supported:

- `\\` — Backslash

- `\n` — Newline character

- `\t` — Tab character

- `\b` — Backspace character

- `\r` — Carriage return

- `\'` — Single quote (somewhat unnecessary, as single quotes are allowed in Sail strings)

- `\"` — Double quote

- `\DDD` — The character with decimal ASCII code `DDD`

- `\xHH` — The character with hexadecimal ASCII code `HH`

Multi-line strings can be written by escaping the newline character at the end of a line:

``` rouge
print_endline("Hello, \
               World!");
// Is equivalent to
print_endline("Hello, World!")
```

### User-defined types

Sail supports various kinds of user-defined types: *structs*, *unions*, and *enums*.

#### Structs

Like in C, structs are used to hold multiple values. Structs are created using the `struct` keyword followed by the name of the struct. The data the struct contains is then defined following the `=` symbol. Each piece of data stored in a struct is called a `field`, and each is given a unique name that identifies that piece of data, and can have a different type.

The following example struct defines three fields. The first contains a bitvector of length 5 and is called `field1`. The second, `field2` contains an integer. The third, `field3` contains a string.

``` rouge
struct My_struct = {
  field1 : bits(5),
  field2 : int,
  field3 : string,
}
```

We can then construct struct values by using the `struct` keyword and providing values for all the fields. The individual fields can be accessed using the `.` operator. If the struct is mutable, we can also the `.` operator on the left-hand side of an assignment to assign to the struct field. For immutable structs, we can update them using the `with` keyword, which will create a new struct value with some fields changed.

``` rouge
  let s : My_struct = struct {
    field1 = 0b11111,
    field2 = 5,
    field3 = "test",
  };

  // Accessing a struct field, prints "field1 is 0b11111"
  print_bits("field1 is ", s.field1);

  // Updating struct fields, creating a new struct variable s2
  var s2 = { s with field1 = 0b00000, field3 = "a string" };

  // Prints "field1 is 0b00000"
  print_bits("field1 is ", s2.field1);
  // Prints "field2 is 5", as field2 was taken from 's' and not modified
  print_int("field2 is ", s2.field2);

  // Because s2 is mutable we can assign to it
  s2.field3 = "some string";
  // Prints "some string"
  print_endline(s2.field3)
```

Structs can have user defined type parameters. The following example has an integer parameter `'n` and a type parameter `'a`.

``` rouge
struct My_other_struct('n, 'a) = {
  a_bitvector : bits('n),
  something : 'a
}
```

The struct can then be instantiated with any length of bitvector for the `a_bitvector` field, and any data type for the `something` field, including another struct like the `My_struct` type we defined earlier.

``` rouge
  var s3 : My_other_struct(2, string) = struct {
    a_bitvector = 0b00,
    something = "a string"
  };

  var s4 : My_other_struct(32, My_struct) = struct {
    a_bitvector = 0xFFFF_FFFF,
    something = struct {
      field1 = 0b11111,
      field2 = 6,
      field3 = "nested structs!",
    }
  };

  s3.a_bitvector = 0b11;

  // Note that once created, we cannot change a variable's type, so the following is forbidden:
  // s3.a_bitvector = 0xFFFF_FFFF;

  // Changing the type is also forbidden in a with expression:
  // let s4 : My_other_struct(32, string) = { s3 with a_bitvector = 0xFFFF_FFFF };

  // If structs are nested, then field accesses can also be nested
  print_endline(s4.something.field3);
  // and assignments
  s4.something.field3 = "another string"
```

#### Enums

Sail enumerations are also much like their C counterparts. An enum is declared using the `enum` keyword followed by the name of the enumeration type. The members of the enumeration are specified as a comma-separated list of identifiers between curly braces, like so:

``` rouge
enum My_enum = {
  Foo,
  Bar,
  Baz,
  Quux,
}
```

The above style is best when there are a lot of elements in the enumeration. We allow enums to be defined in a style similar to Haskell, where the identifiers are separated by a vertical bar `|` character, like so:

``` rouge
enum My_short_enum = A | B | C
```

This style is better when the enumeration is short and has few constructors, however specification authors may prefer to use the first style exclusively for consistency.

Sail will automatically generate functions for converting enumeration members into numbers, starting with 0 for the first element of the enumeration.

``` rouge
function enum_example1() = {
  assert(num_of_My_enum(Foo) == 0);
  assert(num_of_My_enum(Bar) == 1);
  assert(num_of_My_enum(Baz) == 2);
  assert(num_of_My_enum(Quux) == 3);
}
```

Likewise, there is a function for converting the other way

``` rouge
function enum_example2() = {
  assert(My_enum_of_num(0) == Foo)
}
```

If the names of the generated functions are not ideal, then custom names can be provided using the `enum_number_conversions` attribute.

``` rouge
$[enum_number_conversions { from_enum = to_number, to_enum = from_number }]
enum Another_enum = {
  Member1,
  Member2,
}

function custom_conversions() -> unit = {
  assert(to_number(Member1) == 0);
  assert(from_number(1) == Member2);
}
```

The `no_enum_number_conversions` attribute can be used to disable the generation of these functions entirely.

We also support generating a vector containing all elements of the enumeration, using the `enum_vector` attribute.

``` rouge
$[enum_vector my_enum_members]
enum My_other_enum = { M1, M2, M3 }

function iterate() = {
  foreach (i from 0 to (length(my_enum_members) - 1)) {
    match my_enum_members[i] {
      M1 => print_endline("1"),
      M2 => print_endline("2"),
      M3 => print_endline("3"),
    }
  }
}
```

#### Unions

Structs provide us a way to group multiple pieces of related data, for example

``` rouge
struct rectangle = {
    width : int,
    height : int,
}
```

defines a type `rectangle` that has both a width *and* a height. The other logical way to combine data is if we want to say we have some data *or* some other data, like if we wanted to represent a shape that could be a circle *or* a rectangle. In Sail, we use a *union* for this.

``` rouge
struct circle = { radius : int }

union shape = {
    Rectangle : rectangle,
    Circle : circle,
}
```

[TABLE]

This defines a type with two *constructors* `Rectangle` and `Circle`. Constructors are used like functions with a single argument, as so:

``` rouge
function example() = {
    // Construct a shape using the Rectangle constructor
    let r : shape = Rectangle(struct { width = 30, height = 20 });

    // Construct a shape using the Circle constructor
    // Note that we can allow the 'shape' type to be inferred
    let c = Circle(struct { radius = 15 });
}
```

To destructure unions, we typically use *pattern matching* to handle each case in the union separately. This will be discussed in detail in [Pattern matching](#_pattern_matching).

Constructors in Sail always have a single argument. If we want a constructor in a union type to contain no information, then we can use the `unit` type. For a constructor with multiple arguments we can use a tuple type. We provide some syntax sugar that allows writing constructor applications with either tuple or unit argument types as if they were functions with multiple arguments or no arguments respectively.

``` rouge
union example_unit_constructor = {
  Foo : (int, string),
  Bar : unit,
}

// Using a constructor with a tuple type
let x1 = Foo(2, "a string")

// Note that the above is equivalent to
let x2 = Foo((2, "a string"))

// Using a unit-type constructor
let y1 = Bar()

// Similarly, equivalent to
let y2 = Bar(())
```

In our shape example, we defined `rectangle` and `circle` as two separate structs, but if we wanted we could declare those structs inline

``` rouge
union shape2 = {
    Rectangle2 : { width : int, height : int },
    Circle2 : { radius : int },
}
```

Behind the scenes, Sail will just generate separate struct definitions, so we use this type in exactly the same was as we did previously.

As with structs, we can define polymorphic union types, like

``` rouge
union either('a, 'b) = {
    Left : 'a,
    Right : 'b,
}
```

#### `newtype`

There is a slight variation of the `union` keyword, which allows constructing a union with just a single constructor:

``` rouge
newtype register_index = Mk_index : bits(5)
```

this is semantically equivalent to

``` rouge
union register_index = {
  Mk_index : bits(5)
}
```

The main difference from is that for certain Sail targets (including C, SMT, and SystemVerilog) `register_index` will be compiled as if it were `bits(5)` directly.

The purpose of the `newtype` construct is to create an alias for an existing type which is distinct from the perspective of the type system — We cannot accidentally pass any `bits(5)` where a `register_index` index is required, as register indices must have been explicitly constructed using `Mk_index`. This means that using `newtypes` can increase type-safety and therefore prevent errors, unlike regular type synonyms which we discuss below.

### Type synonyms

We have now described all the various types available in Sail. However, in order to create more descriptive and self-documenting specifications, we might want to give types new names that better inform the reader of the intent behind the types. We can do this using *type synonyms*, which are created with the `type` keyword.

For example, if we have an architecture with 32 general purpose registers, we might want to index them using a 5-bit type. Rather than using `bits(5)` directly, we create a synonym:

``` rouge
type regbits = bits(5)
```

We can now write functions that use this type:

``` rouge
register R1 : bits(32)
register R2 : bits(32)

function access_register(r : regbits) -> bits(32) = {
  match r {
     0b00000 => 0x0000_0000, // zero register
     0b00001 => R1,
     0b00010 => R2,
     // and so on
  }
}
```

Sail types also include numbers, as in `bits(32)` above. We can therefore write a type synonym for just such a number:

``` rouge
type xlen = 32
```

In which case, we could re-write our example as

``` rouge
register R1 : bits(xlen)
register R2 : bits(xlen)

function access_register(r : regbits) -> bits(xlen) = {
  match r {
     0b00000 => 0x0000_0000, // zero register
     0b00001 => R1,
     0b00010 => R2,
     // and so on
  }
}
```

Type synonyms are completely transparent to the Sail type-checker, so a type synonym can be used exactly the same as the original type.

We can also write type-synonyms that have arguments, for example:

``` rouge
type square('n, 'a) = vector('n, vector('n, 'a))
```

### Type kinds

Throughout the previous section we have seen many different types. For example we could have a type like `list(int)`, or a type like `range(2, 5)`. The `range` type takes two numbers as an arguments, whereas list takes a type as an argument. We’ve also seen polymorphic user-defined types like:

``` rouge

struct foo('n, 'a) = {
  some_bits : bits('n),
  some_a : 'a,
}
```

Which we could use as the type `foo(32, string)`, or `foo(16, int)`. What stops us from writing `foo(string, int)` or even `range(int, int)` or `list(3)` however? Those should clearly be type errors, and if they are type errors *does that mean types have types*? The answer to this is yes, and we call the types of types *kinds*. Sail has three different kinds of types, which we denote as `Int`, `Bool`, and `Type`. The `Int` kind is for type-level integers, `Bool` is for type-level (boolean) constraints, and `Type` is for ordinary types. Type constructors therefore have types much like functions, with `list` having the type `Type → Type` and `range` having the type `(Int, Int) → Type`.

[TABLE]

Sail allows writing the kinds explicitly in type definitions, so we could write:

``` rouge
struct foo('n : Int, 'a : Type) = {
  some_bits : bits('n),
  some_a : 'a,
}
```

but in practice we don’t need to do this, as Sail has kind-inference to avoid us having to think about this particular detail.

### Abstract types

Consider the following problem: We want to specify an architecture like RISC-V, which permits both 32-bit and a 64-bit implementations, with the two implementations being mostly the same other than the base ISA width (called XLEN in RISC-V).

In Sail, we could write something like:

``` rouge
$ifdef RV32
type xlen = 32
$else
type xlen = 64
$endif

register X1 : bits(xlen)
```

However, this has the problem that if we write a function like:

``` rouge
function rv32_only() = {
    X1 = 0xFFFF_FFFF
}
```

it will typecheck and build fine only when `RV32` is defined, but will fail otherwise when `xlen = 64`.

What we really want is to write a specification that is truely *parametric* over the choice of `xlen`. In Sail we can do this by leaving the `xlen` type *abstract*, which means we do not provide a concrete value for it during type-checking. This would look like:

``` rouge
type xlen : Int

constraint xlen in {32, 64}
```

If we then try to write the above `rv32_only` function, we will get an error

``` rouge
Type error:
../examples/abstract_error.sail:4.9-20:
4 |    X1 = 0xFFFF_FFFF
  |         ^---------^
  | Failed to prove constraint: 32 == xlen
  | 
  | constraint from ../examples/abstract_xlen.sail:10.19-23:
  | 10 |register X1 : bits(xlen)
  |    |                   ^--^ This type argument
```

as `xlen` is not guaranteed to be 32.

Not all Sail targets support abstract types, so for some targets the abstract types must be instantiated to concrete values before generating definitions. We do this using the `--instantiate` option, so if the above file is called `xlen.sail`, we could do:

``` rouge
sail xlen.sail --lem --instantiate xlen=32
```

To create lem definitions for the `xlen = 32` case.

### Pattern matching

Like most functional languages, and an increasing number of imperative languages like Rust, Sail supports *pattern matching* via the `match` keyword. For example:

``` rouge
let n : int = f();
match n {
    1 => print_endline("1"),
    2 => print_endline("2"),
    3 => print_endline("3"),
    _ => print_endline("wildcard"),
}
```

The `match` keyword takes an expression and then branches by comparing the matched value with a *pattern*. Each case in the match expression takes the form `<pattern> => <expression>`, separated by commas (a trailing comma is allowed). The cases are checked sequentially from top to bottom, and when the first pattern matches its expression will be evaluated.

The concrete match statement syntax in Sail is inspired by the syntax used in Rust — but programmers coming from languages with no pattern matching features may be unfamiliar with the concept. One can think of the match statement like a super-powered switch statement in C. At its most basic level a match statement can function like a switch statement (except without any fall-through). As in the above example we can use match to compare an expression against a sequence of values like so:

``` rouge
match expression {
    1 => print_endline("expression == 1"),
    2 => {
        // A match arm can have a single expression or a block
        // (because blocks in Sail are also expressions!)
        print_endline("expression == 2")
        // Note that unlike in C, no 'break' is needed as there is no fallthrough
    },
    _ => print_endline("This wildcard pattern acts like default: in a C switch")
}
```

However the pattern in a match statement can also *bind* variables. In the following example we match on a numeric expression `x + y`, and if it is equal to `1` we execute the first match arm. However, if that is not the case the value of `x + y` is bound to a new immutable variable `z`.

``` rouge
match x + y {
    1 => print_endline("x + y == 1"),
    z => {
        // here z is a new variable defined as x + y.
        print_int("x + y = ", z)
        // z is only defined within the match arm
    },
}
```

Finally, we can use patterns to *destructure* values — breaking them apart into their constituent parts. For example if we have a pair expression we can break it apart into the first value in the pair and the second, which can then be used as individual variables:

``` rouge
match pair : (int, int) {
    (first, second) => {
        // here we have split a pair into two variables first and second
        print_int("first = ", first);
        print_int("second = ", second)
    }
}
```

These features can be combined, so if we had a pattern `(first, 3)` in the above example, the expression for that pattern would be executed when the second element of the pair is equal to 3, and the first element would be bound to the variable `first`.

Sail will check match statements for exhaustiveness (meaning that the patterns in the match cover every possible value), and prints a warning if the overall match statement is not exhaustive. There are some limitations on the exhaustiveness checker which we will discuss further below.

#### Guards

What if we need to switch based on more complex logic than just the structure and values of the expressions we are matching on? For this matches in Sail support *guards*. A guard allows us to combine the behavior of a match expression and the boolean logic of an if expression — and the syntax is reflective of this, as we can use the `if` keyword to add extra logic to each match arm:

``` rouge
match x + y {
    z if z > 0  => print_endline("y is greater than 0"),
    z if z == 0 => print_endline("z is equal to 0"),
    z           => print_endline("z is less than 0"),
}
```

You may wonder — why not write `z if z < 0` for the final case? Here we run into one of the limitations of the exhaustiveness checker mentioned above. Sail can only check the exhaustiveness of *unguarded* clauses, meaning that the checker only considers cases without an `if` guard. The `z` pattern by itself is exhaustive, so the checker is happy, but if we added a `if z < 0` guard the checker would complain that there are no unguarded patterns for it to look at. This may seem suprising for such a simple case (we can easily see the three guards would cover all cases!), however each guard clause could contain arbitrarily complex logic potentially abstracted behind arbitrary function calls, which the completeness checker cannot reason about.

We now describe all the things that can be matched on in Sail

#### Matching on literals

First, and as we have already seen, we can match on literal values. These literal values can be `()`, bitvectors, the boolean values `true` and `false`, numbers, and strings.

#### Matching on enumerations

Match can be used to match on possible values of an enum, like so:

``` rouge
match x {
    A => print_endline("A"),
    B => print_endline("B"),
    C => print_endline("C")
}
```

Note that because Sail places no restrictions on the lexical structure of enumeration elements to differentiate them from ordinary identifiers, pattern matches on variables and enum elements can be somewhat ambiguous. Issues with this are usually caught by the exhaustiveness checker — it can warn you if removing an enum constructor breaks a pattern match.

#### Matching on tuples

We use match to destructure tuple types, for example:

``` rouge
let x: (int, int) = (2, 3);
match x {
    (y, z) => print_endline("y = 2 and z = 3")
}
```

#### Matching on unions

Match can also be used to destructure tagged union constructors, for example using the option type from the Sail library.

``` rouge
$include <option.sail>

val g : unit -> option(int)

function match_union() -> unit = {
    let x = g();
    match x {
        Some(n) => print_int("n = ", n),
        None()  => print_endline("got None()!"),
    }
}
```

Note that like how calling a function with a unit argument can be done as `f()` rather than `f(())`, matching on a constructor `C` with a unit type can be achieved by using `C()` rather than `C(())`.

#### Matching on lists

Sail allows lists to be destructured using patterns. There are two types of patterns for lists, cons patterns and list literal patterns. The cons pattern destructures lists into the first element (the *head*) and the rest of the list (the *tail*).

``` rouge
match ys {
    x :: xs => print_endline("cons pattern"),
    [||]    => print_endline("empty list")
}
```

On the other hand, a list pattern matches on the entire list:

``` rouge
match ys {
    [|1, 2, 3|] => print_endline("list pattern"),
    _           => print_endline("wildcard")
}
```

#### Matching on structs

Match can also be used for structures, for example:

``` rouge
struct my_struct = {
    field1 : bits(16),
    field2 : int,
}

function match_struct(value : my_struct) -> unit = {
    match value {
        // match against literals in the struct fields
        struct { field1 = 0x0000, field2 = 3 } => (),

        // bind the struct field values to immutable variables
        struct { field1 = x, field2 = y } => {
            print_bits("value.field1 = ", x);
            print_int("value.field2 = ", y)
        }
    }
}
```

We can omit fields from the match by using a wildcard `_` in place of some of the fields:

``` rouge
match value {
    struct { field1 = x, _ } => {
        print_bits("value.field1 = ", x)
    }
}
```

Finally, if we want to create a variable with the same name as a field, rather than typing `struct { field_name = field_name, _ }`, we can shorten this to just `struct { field_name, _ }`, So the above example is equivalent to:

``` rouge
match value {
    struct { field1, _ } => {
        print_bits("value.field1 = ", field1)
    }
}
```

#### As patterns

Like OCaml, Sail also supports naming parts of patterns using the `as` keyword. For example, in the above cons pattern example we could bind the entire matched list to the `zs` variable:

``` rouge
match (1 :: 2 :: ys) : list(int) {
    x :: xs as zs => print_endline("cons with as pattern"),
    [||]          => print_endline("empty list"),
}
```

The `as` pattern has lower precedence than any other keyword or operator in a pattern, so in this example the pattern brackets as `(x :: xs) as zs`

#### Automatic wildcard insertion

The various theorem provers that Sail can produce definitions for are often strict, and enforce that pattern matches are exhaustive. However, their pattern exhaustiveness checkers do not understand bitvectors in the same way Sail does. For example, Sail can tell that the following match is complete:

``` rouge
match (x, y) {
    (0b1, _)   => print_endline("1"),
    (_, 0b0)   => print_endline("2"),
    (0b0, 0b1) => print_endline("3"),
}
```

When translating to a target without bitvector literals, this would be rewritten to use guards:

``` rouge
match (x, y) {
    (t1, _) if t1 == 0b1 => print_endline("1"),
    (_, t2) if t2 == 0b0 => print_endline("2"),
    (t1, t2) if t1 == 0b0 & t2 == 0b1 => print_endline("3"),
}
```

Most targets that check pattern exhaustiveness share the same limitation as Sail — they only check match arms without guards, so they would not see that this match is complete. To avoid this, Sail will attempt to replace literal patterns with wildcards when possible, so the above will be rewritten to:

``` rouge
match (x, y) {
    (0b1, _) => print_endline("1"),
    (_, 0b0) => print_endline("2"),
    (_, _)   => print_endline("3"),
}
```

which is equivalent.

One can find situations where such wildcards cannot be inserted. For example:

``` rouge
function cannot_wildcard(x: option(bits(1)), y: option(bits(1))) -> unit = {
    match (x, y) {
        (Some(0b0), Some(_))   => print_endline("1"),
        (Some(0b1), Some(0b0)) => print_endline("2"),
        (Some(0b1), _)         => print_endline("3"),
        (Some(0b0), None())    => print_endline("4"),
        (None(), _)            => print_endline("5"),
    }
}
```

Here the `0b1` literal in the `(Some(0b1), _)` case would need to be replaced for an exhaustiveness checker without bitvector literals to check the case where `x` and `y` are both `Some`, but this would change the behavior when `x` is `Some` and `y` is `None`, hence a wildcard cannot be inserted.

In this case Sail will print a warning explaining the problem:

``` rouge
Warning: Required literal ../examples/cannot_wildcard.sail:17.14-17:
17 |        (Some(0b1), _)         => print_endline("3"),
   |              ^-^
   | 
Sail cannot simplify the above pattern match:
This bitvector pattern literal must be kept, as it is required for Sail to show that the surrounding pattern match is complete.
When translated into prover targets (e.g. Lem, Coq) without native bitvector patterns, they may be unable to verify that the match covers all possible cases.
```

This warning should be heeded, and the match simplified otherwise the generated theorem prover definitions produced by Sail may be rejected by the prover.

### Matching in let and function arguments

The `match` statement isn’t the only place we can use patterns. We can also use patterns in function arguments and with `let`, for example:

``` rouge
struct S = {
    field1 : int,
    field2 : string,
}

function example1(s : S) -> unit = {
    // Destructure 's' using let
    let struct { field1, _ } = s;
    print_int("field1 = ", field1)
}

// Destructure directly in the function argument
function example2(struct { field1, _ } : S) -> unit = {
    print_int("field1 = ", field1)
}
```

### Type patterns

In the previous section we saw as patterns, which allowed us bind additional variables for subpatterns. However, as patterns can also be used to bind type variables. For example:

``` rouge
// Some function that returns either 32 or 64 at runtime
val get_current_xlen : unit -> {32, 64}

register R : bits(32)

val example : unit -> unit

function example() = {
  let xlen as int('n) = get_current_xlen()

  // Create a bitvector of length xlen
  let bv : bits('n) = zero_extend(xlen, *R);

  print_bits("bv = ", bv)
}
```

You can think of the `as int('n)` as matching on the return type of the `get_current_xlen` rather than the value, and binding its length to a new type variable `'n`, which we can subsequently use in types later in our function. Note that even though we only know if xlen will be 32 or 64 at runtime after the call to get_current_xlen, Sail is still able to statically check all our bitvector accesses.

If a type only contains a single type variable (as `int('n)` does), then we allow omitting the type name and just using a variable as the type pattern, for example the following would be equivalent to the first line of example above:

``` rouge
let xlen as 'n = get_current_xlen();
```

If we want to give the variable `xlen` and the type variable `'n` the same name, we could go further and simplify to:

``` rouge
function example() = {
  let 'xlen = get_current_xlen()

  // Create a bitvector of length xlen
  let bv : bits('xlen) = zero_extend(xlen, *R);

  print_bits("bv = ", bv)
}
```

Here we can use xlen within the function as both a regular variable `xlen` and as a type variable `'xlen`.

### Mutable variables

Bindings made using `let` are always immutable, but Sail also allows mutable variables. Mutable variables are created by using the `var` keyword within a block.

``` rouge
{
  var x : int = 3; // Create a new mutable variable x initialised to 3
  x = 2            // Rebind it to the value 2
}
```

Like let-bound variables, mutable variables are lexically scoped, so they only exist within the block that declared them.

Technically, unless the `--strict-var` option is used Sail also allows mutable variables to be implicitly declared, like so:

``` rouge
{
  x : int = 3 // Create a new mutable variable x initialised to 3
  x = 2       // Rebind it to the value 2
}
```

This functions identically, just without the keyword. We consider this deprecated and strongly encourage the use of the `var` keyword going forwards.

The assignment operator is the equality symbol, as in C and other programming languages. Sail supports a rich language of *l-value* forms, which can appear on the left of an assignment. These will be described in the next section.

One important thing to note is that Sail always infers the most specific type it can for variables, and in the presence of integer types with constraints, these types can be *very* specific. This is not a problem for immutable bindings, but can cause issues for mutable variables when explicit types are omitted. The following will not typecheck:

``` rouge
{
  var x = 3;
  x = 2;
}
```

The reason is that Sail (correctly) infers that `x` has the type 'the integer equal to 3', and therefore refuses to allow us to assign `2` to it (as it well should), because two is not equal to three. To avoid this we must give an annotation with a less specific type like `int`.

### Assignment and l-values

It is common in ISA specifications to assign to complex l-values, e.g. to a subvector or named field of a bitvector register, or to an l-value computed with some auxiliary function, e.g. to select the appropriate register for the current execution model.

Sail has l-values that allow writing to individual elements of a (bit)vector:

``` rouge
var v : bits(8) = 0xFF;
v[0] = bitzero;
assert(v == 0xFE)
```

As well as sub-ranges of a (bit)vector:

``` rouge
var v : bits(8) = 0xFF;
v[3 .. 0] = 0x0; // assume default Order dec
assert(v == 0xF0)
```

We also have vector concatenation l-values, which work much like vector concatenation patterns

``` rouge
var v1 : bits(4) = 0xF;
var v2 : bits(4) = 0xF;
v1 @ v2 = 0xAB;
assert(v1 == 0xA & v2 == 0xB)
```

For structs we can write to an individual struct field as

``` rouge
// Assume S is a struct type with a single bits(8) field (called field)
var s : S = struct { field = 0xFF };
s.field = 0x00;
assert(s.field == 0x00)
```

We can also do multiple assignment using tuples, for example:

``` rouge
var (x, y) = (2, 3);
assert(x == 2 & x == 3)
// swap values
(y, x) = (x, y)
assert(x == 3 & x == 2)
```

Finally, we allow functions to appear in l-values. This is a very simple way to declare *setter functions* that look like custom l-values, for example:

``` rouge
memory(addr) = 0x0F
// is just syntactic sugar for
memory(addr, 0x0F)
```

This feature is commonly used when setting registers or memory that have some additional semantics when they are read or written. We commonly use the ad-hoc overloading feature to declare what appear to be getter/setter pairs, so for the above example we could implement a `read_memory` function and a `write_memory` function and overload them both as `memory` to allow us to write memory using `memory(addr) = data` and read memory as `data = memory(addr)`, for example:

``` rouge
val read_memory : bits(64) -> bits(8)
val write_memory : (bits(64), bits(8)) -> unit

overload memory = {read_memory, write_memory}
```

### Registers

We have discussed mutable variables defined with `var`, and assignment to those variables in the previous sections. The global state of an ISA is defined in Sail by a set of *registers*, which essentially act as global mutable variables. For example, we could define and use a register as follows:

``` rouge
register R : bits(64)

function writes_to_R() -> unit = {
  // writing to a register
  R = 0xFFFF_FFFF_FFFF_FFFF;

  R[15 .. 0] = 0x1111;
}

function reads_from_R() -> unit = {
  // reading from a register
  print_bits("the value of the register is ", R)
}
```

We can provide a default initial value to a register, or leave it undefined. In the above example the register definition is equivalent to writing

``` rouge
register R : bits(64) = undefined
```

For readability reasons, local variables are not permitted to shadow global register definitions, as the following example demonstrates.

``` rouge
default Order dec

$include <prelude.sail>

register X : bits(16)

function shadows_register() -> unit = {
  var X : bits(32) = 0xFFFF_FFFF;
  ()
}
```

``` rouge
Warning: Redundant type annotation on assignment to X ../examples/register_shadow.sail:8.6-18:
8 |  var X : bits(32) = 0xFFFF_FFFF;
  |      ^----------^
  | 
Type is already known

Type error:
../examples/register_shadow.sail:8.6-18:
8 |  var X : bits(32) = 0xFFFF_FFFF;
  |      ^----------^
  | var expression can only be used to declare new variables, not update them
```

### Bitfields

The following example creates a bitfield type called `cr_type` and a register `CR` of that type. The underlying bitvector type (in this case `bits(8)`) must be specified as part of the bitfield declaration.

[TABLE]

``` rouge

bitfield cr_type : bits(8) = {
  CR0 : 7 .. 4,
  LT  : 7,
  GT  : 6,
  CR1 : 3 .. 2,
  CR3 : 1 .. 0
}

register CR : cr_type
```

If the bitvector is decreasing then indexes for the fields must also be in decreasing order, and vice-versa for an increasing vector. The field definitions can be overlapping and do not need to be contiguous.

A bitfield generates a type that is simply a struct wrapper around the underlying bitvector, with a single field called `bits` containing that bitvector. For the above example, this will be:

``` rouge
struct cr_type = {
  bits : bits(8)
}
```

This representation is guaranteed, so it is expected that Sail code will use the `bits` field to access the underlying bits of the bitfield as needed. The following function shows how the bits contained in a bitfield can be accessed:

``` rouge
function bitfield_access_example() = {
  // Rather than using numeric indices, the bitfield names are used
  let cr0_field : bits(4) = CR[CR0];

  // Bitfield accessors always return bitvector results
  let lt_field : bits(1) = CR[LT]; // Note 'bits(1)' not 'bit'

  // Can access the underlying bitvector using the bits field
  let some_bits : bits(7) = CR.bits[6 .. 0];
}
```

Similarly, bitfields can be updated much like regular vectors just using the field names rather than numeric indices:

``` rouge
function bitfield_update_example() = {
  // We can set fields on the CR register using their field names
  CR[CR3] = 0b01;

  // If we want to set the underlying bits
  CR.bits[1 .. 0] = 0b01;

  // We can even use vector update notation!
  CR = [CR with CR3 = 0b01, LT = 0b1];

  // Because of the representation, we could set the whole thing like:
  CR = (struct { bits = 0x00 } : cr_type);
}
```

In the case of overlapping fields, the vector update notion will update the fields in order from left to right.

Older versions of Sail did not guarantee the underlying representation of the bitfield (because it tried to do clever things to optimise them). This meant that bitfields had to be accessed using getter and setter functions, like so:

``` rouge
function legacy_bitfields() = {
  // Assigning to a field of a bitfield register
  CR->CR3() = 0b01;
  // '->' notation just means the setter takes the register by reference:
  (ref CR).CR3() = 0b01;

  // Assigning all the bits (now just 'CR.bits = 0x00')
  CR->bits() = 0x00;

  // Accessing a field
  let cr0_field : bits(4) = CR.CR0();

  // Updating a field
  CR = update_CR3(CR, 0b01); // now '[ CR with CR3 = 0b01 ]'

  // Construct a new CR bitfield
  CR = Mk_cr_type(0x00);
}
```

The method like accessor syntax was (overly sweet) syntactic sugar for getter and setter functions following a specific naming convention that was generated by the bitfield. These functions are still generated for backwards compatibility, but we would advise against using them.

[TABLE]

### Operators

Valid operators in Sail are sequences of the following non alpha-numeric characters: `!%&*+-./:<>=@^|#`. Additionally, any such sequence may be suffixed by an underscore followed by any valid identifier, so `<=_u` or even `<=_unsigned` are valid operator names. Operators may be left, right, or non-associative, and there are 10 different precedence levels, ranging from 0 to 9, with 9 binding the tightest. To declare the precedence of an operator, we use a fixity declaration like:

``` rouge
infix 4 <=_u
```

For left or right associative operators, we’d use the keywords `infixl` or `infixr` respectively. An operator can be used anywhere a normal identifier could be used via the `operator` keyword. As such, the `<=_u` operator can be defined as:

``` rouge
val operator <=_u : forall 'n. (bits('n), bits('n)) -> bool
function operator <=_u(x, y) = unsigned(x) <= unsigned(y)
```

By default, Sail defines the basic arithmetic operators `*`, `\`, `%`, `+`, and `-`, for integer multiplication, division, modulus, addition, and subtraction respectively. The Sail library also overloads addition and subtraction for bitvectors, performing two’s complement arithmetic over bitvectors with matching sizes. Adding a bitvector and an integer is also allowed, i.e. `0x01 + N`. For small bitvectors and large integers this is equivalent to adding 1 to the bitvector `N` times, wrapping each time the value overflows, for example:

``` rouge
0xFF + 2 == (0xFF + 0x01) + 0x01 == 0x01
// Wrapping multiple times:
0b0 + 3 == ((0b0 + 0b1) + 0b1) + 0b1 = ((0b1 + 0b1) + 0b1) = 0b0 + 0b1 = 0b1
```

The comparison operators `<`, `⇐`, `>`, `>=`, `!=`, and `==` all compare integers. We don’t define bitvector comparisons by default, as bitvectors can be compared as either signed or unsigned. Individual ISA specifications may choose to overload these operators or define their own as needed.

The boolean operators `&` (logical and) and `|` (logical or) compare boolean values. Note that when applied to booleans they have short-circuiting semantics. The standard library overloads these operators for bitwise operations on bitvectors of the same length.

The exponentiation operator `^` is slightly special. The Sail parser recognises the special case `2 ^ x` directly and maps that to a special `pow2(x)` function. This is because `2 ^ x` is the only form of exponentiation we permit in numeric types. The `^` operator can otherwise be overloaded by ISA specs as a normal operator.

The `@` operators is used to concatenate bitvectors and generic vectors. As demonstrated in the pattern matching section [Pattern matching](#_pattern_matching), it can also be used to destructure them. Similarly, the cons operator `::` is used to construct lists (see section [\[The list type\]](#The%20list%20type)).

#### Built-in precedences

The precedence of several common operators are built into Sail. These include all the operators that are used in type-level numeric expressions, as well as several common operations such as equality, division, and modulus. The precedences for these operators are summarised in the following table.

| Precedence | Left associative | Non-associative       | Right associative |
|------------|------------------|-----------------------|-------------------|
| 9          |                  |                       |                   |
| 8          |                  |                       | `^`               |
| 7          | `*, \, %`        |                       |                   |
| 6          | `+, -`           |                       |                   |
| 5          |                  |                       | `::, @`           |
| 4          |                  | `<, ⇐, >, >=, !=, ==` |                   |
| 3          |                  |                       | `&`               |
| 2          |                  |                       | `|`               |
| 1          |                  |                       |                   |
| 0          |                  |                       |                   |

Table 1. Default Sail operator precedences {.tableblock .frame-all .grid-all style="width: 80%;"}

### Ad-hoc overloading

Sail has a flexible overloading mechanism using the overload keyword. For example:

``` rouge
overload foo = {bar, baz}
```

It takes an identifier name, and a list of other identifier names to overload that name with. When the overloaded name is seen in a Sail definition, the type-checker will try each of the overloads (that are in scope) in order from left to right until it finds one that causes the resulting expression to type-check correctly.

Multiple `overload` declarations are permitted for the same identifier, with each overload declaration after the first adding its list of identifier names to the right of the overload list (so earlier overload declarations take precedence over later ones). As such, we could split every identifier from above example into its own line like so:

``` rouge
overload foo = {bar}
overload foo = {baz}
```

Note that if an overload is defined in module `B` using identifiers provided by another module `A`, then a module `C` that requires only `B` will not see any of the identifiers from `A`, unless it also requires `A`. See the section on modules for details. Note that this means an overload cannot be used to 're-export' definitions provided by another module.

As an example for how overloaded functions can be used, consider the following example, where we define a function `print_int` and a function `print_string` for printing integers and strings respectively. We overload `print` as either `print_int` or `print_string`, so we can print either number such as 4, or strings like `"Hello, World!"` in the following `main` function definition.

``` rouge
val print_int : int -> unit

val print_string : string -> unit

overload print = {print_int, print_string}

function main() : unit -> unit = {
  print("Hello, World!");
  print(4)
}
```

We can see that the overloading has had the desired effect by dumping the type-checked AST to stdout using the following command `sail -ddump_tc_ast examples/overload.sail`. This will print the following, which shows how the overloading has been resolved

``` rouge
function main () : unit = {
  print_string("Hello, World!");
  print_int(4)
}
```

This option can sometimes be quite useful for observing how overloading has been resolved. Since the overloadings are done in the order they are defined, it can be important to ensure that this order is correct. A common idiom in the standard library is to have versions of functions that guarantee more constraints about their output be overloaded with functions that accept more inputs but guarantee less about their results. For example, we might have two division functions:

``` rouge
val div1 : forall 'm 'n, 'n >= 0 & 'm > 0. (int('n), int('m)) -> {'o, 'o >= 0. int('o)}

val div2 : (int, int) -> option(int)
```

The first guarantees that if the first argument is greater than or equal to zero, and the second argument is greater than zero, then the result will be greater than or equal to zero. If we overload these definitions as

``` rouge
overload operator / = {div1, div2}
```

Then the first will be applied when the constraints on its inputs can be resolved, and therefore the guarantees on its output can be guaranteed, but the second will be used when this is not the case, and indeed, we will need to manually check for the division by zero case due to the option type. Notice that the return type can be different between different cases in the overload.

### Mappings

Mappings are a feature of Sail that allow concise expression of bidirectional relationships between values that are common in ISA specifications: for example, bit-representations of an enum type, or the encoding-decoding of instructions.

They are defined similarly to functions, with a `val` keyword to specify the type and a definition, using a bidirectional arrow `<->` rather than a function arrow `->`, and a separate `mapping` definition.

``` rouge
val size_bits : word_width <-> bits(2)

mapping size_bits = {
  BYTE   <-> 0b00,
  HALF   <-> 0b01,
  WORD   <-> 0b10,
  DOUBLE <-> 0b11
}
```

As a shorthand, you can also specify a mapping and its type simultaneously:

``` rouge
mapping size_bits2 : word_width <-> bits(2) = {
  BYTE   <-> 0b00,
  HALF   <-> 0b01,
  WORD   <-> 0b10,
  DOUBLE <-> 0b11
}
```

Mappings are used simply by calling them as if they were functions: type inference will determine in which direction the mapping is applied. (This gives rise to the restriction that the types on either side of a mapping must be different.)

``` rouge
let width : word_width = size_bits(0b00);
let width : bits(2) = size_bits(BYTE);
```

Sometimes, because the subset of Sail allowed in bidirectional mapping clauses is quite restrictive, it can be useful to specify the forwards and backwards part of a mapping separately:

``` rouge
mapping size_bits3 : word_width <-> bits(2) = {
  BYTE <-> 0b00,
  HALF <-> 0b01,
  WORD <-> 0b10,
  forwards  DOUBLE => 0b11, // forwards is left-to-right
  backwards 0b11 => DOUBLE, // backwards is right-to-left
}
```

### Sizeof and constraint

Sail allows for arbitrary type variables to be included within expressions. However, we can go slightly further than this, and include both arbitrary (type-level) numeric expressions in code, as well as type constraints. For example, if we have a function that takes two bitvectors as arguments, then there are several ways we could compute the sum of their lengths.

``` rouge
val f : forall 'n 'm. (bits('n), bits('m)) -> unit

function f(xs, ys) = {
  let len = length(xs) + length(ys);
  let len = 'n + 'm;
  let len = sizeof('n + 'm);
  ()
}
```

Note that the second line is equivalent to

``` rouge
  let len = sizeof('n) + sizeof('n)
```

There is also the `constraint` keyword, which takes a type-level constraint and allows it to be used as a boolean expression, so we could write:

``` rouge
function f(xs, ys) = {
  if constraint('n <= 'm) {
    // Do something
  }
}
```

rather than the equivalent test `length(xs) <= length(ys)`. This way of writing expressions can be succinct, and can also make it very explicit what constraints will be generated during flow typing. However, all the constraint and sizeof definitions must be re-written to produce executable code, which can result in the generated theorem prover output diverging (in appearance) somewhat from the source input. In general, it is probably best to use `sizeof` and `constraint` sparingly on type variables.

One common use for sizeof however, is to lower type-level integers down to the value level, for example:

``` rouge
// xlen is a type of kind 'Int'
type xlen = 64

val f : int -> unit

function xlen_example() = {
  let v = sizeof(xlen);
  f(v)
}
```

### Exceptions

Perhaps surprisingly for a specification language, Sail has exception support. This is because exceptions as a language feature do sometimes appear in vendor ISA pseudocode (they are a feature in Arm’s ASL language), and such code would be very difficult to translate into Sail if Sail did not itself support exceptions. In practice Sail language-level exceptions end up being quite a nice tool for implementing processor exceptions in ISA specifications.

For exceptions we have two language features: `throw` statements and `try`--`catch` blocks. The throw keyword takes a value of type `exception` as an argument, which can be any user defined type with that name. There is no built-in exception type, so to use exceptions one must be set up on a per-project basis. The exception type must be a union (except it cannot be declared via `newtype`), and is usually a scattered union to allow exceptions to be declared throughout the specification as they would be in OCaml, for example:

``` rouge
scattered union exception

union clause exception = Epair : (range(0, 255), range(0, 255))

union clause exception = Eunknown : string

function main() : unit -> unit = {
    try {
        throw(Eunknown("foo"))
    } catch {
        Eunknown(msg) => print_endline(msg),
        _ => exit()
    }
}

union clause exception = Eint : int

end exception
```

### Scattered definitions

In a Sail specification, sometimes it is desirable to collect together the definitions relating to each machine instruction (or group thereof), e.g.~grouping the clauses of an AST type with the associated clauses of decode and execute functions, as in the [A tutorial RISC-V style example](#_a_tutorial_risc_v_style_example) section. Sail permits this with syntactic sugar for \`scattered' definitions. Functions, mappings, unions, and enums can be scattered.

One begins a scattered definition by declaring the name and kind (either function or union) of the scattered definition, e.g.

``` rouge
// We can declare scattered types, for either unions or enums
scattered union U

scattered enum E

// For scattered functions and mappings, we have to provide a type signature with val
val foo : U -> bits(64)

scattered function foo

val bar : E <-> string

scattered mapping bar
```

This is then followed by *clauses* for either, which can be freely interleaved with other definitions. It is common to define both a scattered type (either union or enum), with a scattered function that operates on newly defined clauses of that type, as is shown below:

``` rouge
enum clause E = E_one

union clause U = U_one : bits(64)

function clause foo(U_one(x)) = x

mapping clause bar = E_one <-> "first member of E"
```

Finally the scattered definitions are ended with the `end` keyword, like so:

``` rouge
end E

end U

end foo

end bar
```

Technically the `end` keyword is not required, but it is good practice to include it as it informs Sail that the clauses are now complete, which forbids new clauses and means subsequent pattern completeness checks no longer have to require extra wildcards to account for new clauses being added.

Semantically, scattered definitions for types appear at the start of their definition (note however, that this does not mean that a module that requires just the start `scattered union` definition can access any constructors of a union defined in modules it does not require). Scattered definitions for functions and mappings appear at the end. A scattered function definition can be recursive, but mutually recursive scattered function definitions should be avoided.

### Preludes and default environment

By default Sail has almost no built-in types or functions, except for the primitive types described in this Chapter. This is because different vendor-pseudocodes have varying naming conventions and styles for even the most basic operators, so we aim to provide flexibility and avoid committing to any particular naming convention or set of built-ins. However, each Sail backend typically implements specific external names, so for a PowerPC ISA description one might have:

``` rouge
val EXTZ = "zero_extend" : ...
```

while for ARM, to mimic ASL, one would have

``` rouge
val ZeroExtend = "zero_extend" : ...
```

where each backend knows about the `"zero_extend"` external name, but the actual Sail functions are named appropriately for each vendor’s pseudocode. As such each ISA spec written in Sail tends to have its own prelude.

## Model Configuration

Sail includes a configuration system that allows building specifications that can be configured at either runtime (if supported by the Sail backend in use) or statically at build-time using a set of options.

From the perspective of the specification author, one uses the `config` construct to include a value in the specification, for example:

``` rouge
let some_value : string = config foo.bar;
print_endline(some_value);
```

The configuration is some key-value store with dot-separated hierachical keys, so we access the value stored at `foo.bar` key as some string value. In practice, we use JSON to represent these configurations. In this example, the JSON might look something like:

``` rouge
{
    "foo" : {
        "bar" : "Hello, World!"
    }
}
```

Which when used will cause the specification to print `"Hello, World!"`. If we want to statically apply this configuration (and convert the Sail source to OCaml), we could run the following, assuming the configration file is called `file.json` and the Sail file containing the above code is `file.sail`.

``` rouge
$ sail --ocaml --config file.json file.sail
```

### JSON representation of Sail types

The following example demonstrates how basic Sail types are represented in the JSON configuration file. We can load integers, booleans, and strings, all of which correspond directly to the equivalent JSON type. Integers are allowed to be arbitrary precision, as they are in Sail.

``` rouge
  let some_string : string = config some.string_value;
  print_endline(some_string);

  // Booleans are represented as JSON booleans
  let some_bool : bool = config some.bool_value;
  if some_bool then {
    print_endline("some_bool is true")
  };

  // Integers are represented as JSON integers
  let some_int : int = config some.int_value;
  print_int("some_int = ", some_int);

  // Bitvectors have a few allowed representations:
  // We can use a JSON list of booleans
  let some_bits1 : bits(4) = config some.bits_value.one;
  print_bits("some_bits1 = ", some_bits1);

  // That would be unwieldy for larger bitvectors, so we can
  // parse a bitvector from a string with an explicit length.
  let some_bits2 : bits(32) = config some.bits_value.two;
  print_bits("some_bits2 = ", some_bits2);
```

The following JSON can be used to instantiate the above Sail source:

``` rouge
{
    "some" : {
        "string_value" : "A string value",
        "bool_value" : true,
        "int_value" : 48527836473615487354835566752135643523565426,
        "bits_value" : {
            "one" : [true, false, false, true],
            "two" : { "len" : 32, "value" : "0xFF" }
        }
    }
}
```

Note the two permissible representations for bitvectors. First, we can represent them as a list of JSON booleans. This representation has the advantage of being simple and unambiguous regarding the length of the bitvector, but is verbose. Second, we can use a string containing the bitvector value formatted as a Sail bitvector literal (so `_` can be used as a separator) with an explicit integer length. If the value is shorter than the desired width it will be zero-extended. If it is larger then any high bits above the stated width will be ignored (care should be taken to avoid this). In addition to `0b` and `0x` prefixed literals, a decimal value can also be used (also supporting `_` separators), for example:

``` rouge
{ "len" : 32, "value" : "1_000_000" }
```

There are some cases where a specification might need many configuration options. Consider the case of RISC-V PMP registers, where there are up to 64 such registers, and each one might be configured differently. To support this, we allow reading sequences of JSON values into Sail vectors and lists. For example:

``` rouge
  let some_vector : vector(5, int) = config some.json_list;

  // We can also read the configuration value into a Sail list
  let some_list : list(int) = config some.json_list;
```

with the configuration file:

``` rouge
{
    "some" : {
        "json_list" : [1, 2, 3, 4, 5]
    }
}
```

More complex user defined types can also be read from the configuration file. For example, one can read a struct value:

``` rouge
struct my_struct = {
  field1 : int,
  field2 : string,
}

function example1() = {
  let v : my_struct = config some.json_struct;
  print_endline(v.field2);
}
```

or a union value:

``` rouge
union my_union = {
  Constructor1 : int,
  Constructor2 : string,
}

function example2() = {
  let v : my_union = config some.json_union;
  match v {
    Constructor1(n) => print_int("Got integer ", n),
    Constructor2(message) => print_endline(message),
  }
}
```

from the configuration file:

``` rouge
{
    "some" : {
        "json_struct" : {
            "field1" : 3287589457,
            "field2" : "A string value"
        },
        "json_union" : {
            "Constructor2" : "Another string value"
        }
    }
}
```

A Sail struct is represented as a JSON object with keys and values for each field in the struct. There must be a key in the JSON object for every field. A Sail union is represented as a JSON object with exactly one key/value pair. The key must be the name of a constructor in the union, and the value is parsed as the type of the constructor argument.

### Runtime Configuration with Sail to C

The runtime configuration functions are included in the `sail_config.h` header in the `lib/json` subdirectory of the Sail distribution. The `sail_config_set_file` function loads a configuration, and should be called before running any code in a configurable model. The loaded configuration data can be freed by using the `sail_config_cleanup` function.

``` rouge
void sail_config_set_file(const char *path);

void sail_config_cleanup(void);
```

### Configurable abstract types

The [Abstract types](#_abstract_types) section we described how to write a type like `xlen` below without providing a concrete value, in such a way that the specification is parametric over the choice of `xlen`.

``` rouge
type xlen : Int
```

In practice, we likely want to configure this type to have some specific value at runtime. This can be done by associating a configuration option with the abstract type as

``` rouge
type xlen : Int = config arch.xlen
```

which could be instantiated using the following configuration JSON

``` rouge
{ "arch" : { "xlen" : 32 } }
```

We can then create (configurable) bitvector values of length `xlen`:

``` rouge
let x : bits(xlen) = config some.bitvector_value
```

In the configuration file, we specify these by using the string `"xlen"` as the length:

``` rouge
{ "some" : { "bitvector_value" : { "len" : "xlen", "value": "0xFFFF_FFFF" } } }
```

### Validating Configurations with JSON Schema

Above, we discussed how JSON values are mapped onto Sail types, but some questions remain:

- What happens if the configuration we pass at runtime contains impossible values?

- Are all Sail types representable in the JSON configuration?

Note that what we are defining here will necessarily be a weaker notion (i.e. more permissive in the configurations that are possible) than one might consider as the valid configuration space for an ISA definition, as it cannot capture all possible dependencies between different configuration options.

What we want to do is capture is some basic notion of *safety*, i.e. what values can we pass into the model at runtime that won’t break Sail’s typing rules. For example, we might have:

``` rouge
let n : {32, 64} = config some.integer;
```

Then, using the configuration

``` rouge
{
    "some" : {
        "integer" : 72
    }
}
```

we would potentially have some serious problems. Sail could optimize the source using the type annotation that `n` is only 32 or 64, so when we pass 72 at runtime, type-safety would be violated and the model could potentially fail or even exhibit undefined-behaviour when compiled to C! Naturally, we want a way to prevent this from occuring.

To do this we create a [JSON schema](https://json-schema.org) from the way in which the Sail source interacts with the model. JSON schema is an open standard with a wide variety of validators and tooling written in multiple languages.

For the above simple example, the following schema will be generated by Sail when using the `--output-schema` option:

``` rouge
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "some": {
      "type": "object",
      "properties": {
        "integer": {
          "description": "../examples/config_schema.sail:8.21-8.40",
          "anyOf": [
            { "type": "integer", "const": 32 },
            { "type": "integer", "const": 64 }
          ]
        }
      },
      "required": [ "integer" ]
    }
  },
  "required": [ "some" ]
}
```

Now if we attempt to validate the above schema using the JSON containing 72 as the value for the integer, we will get an error

    schema sail_schema/config_schema.json: ok

    instance sail_config/config_schema.json: failed
    - at '/some/integer': anyOf failed
      - at '/some/integer': value must be 32
      - at '/some/integer': value must be 64

In general, whenever we have `config key : T` in the Sail source, we require that the type `T` can be converted into a JSON schema, and raise an error if this is not possible.

## Modular Sail Specifications

### Modules

Sail provides support for organizing large specifications into *modules*. Modules provide an access control mechanism, meaning a Sail definition in one module cannot access or use definitions provided by another module unless it explicitly *requires* the other module.

The module structure of a Sail project/specification is specified in a separate `.sail_project` file.

For a simple example, let’s assume we have two Sail files `amod.sail` and `bmod.sail`:

`amod.sail`

``` rouge
val alfa : unit -> int

function alfa() = 3
```

`bmod.sail`

``` rouge
val bravo : unit -> unit

function bravo() = {
    let x = alfa();
    print_int("alfa returned: ", x)
}
```

We can use the following `.sail_project` file:

`simple_mod.sail_project`

``` rouge
A {
  files amod.sail
}

B {
  requires A
  files bmod.sail
}
```

This file defines two modules `A` and `B`, with module `A` containing the file `amod.sail` and module B containing the file `bmod.sail`. Module `B` requires module `A`, so it can use the `alfa` function defined in `A`. What would happen if we removed the requires line? We would get the following error:

``` rouge
Type error:
../examples/bmod.sail:6.12-16:
6 |    let x = alfa();
  |            ^--^
  | Not in scope
  | 
  | Try requiring module A to bring the following into scope for module B:
  | ../examples/amod.sail:6.4-8:
  | 6 |val alfa : unit -> int
  |   |    ^--^ definition here in A
  | ../examples/simple_mod_err.sail_project:5.0-1:
  | 5 |B {
  |   |^ add 'requires A' within B here
```

This error tells us that `alfa` is not in scope, but Sail knows it exists as it has already checked module `A`, so it points us at the definition and suggests how we could resolve the error by adding the requires line we just removed.

When using a `.sail_project` file we do not have to pass all the files on the command line, so we can invoke Sail simply as

``` rouge
sail simple_mod.sail_project
```

and it will know where to find `amod.sail` and `bmod.sail` relative to the location of the project file.

A module can have more than one Sail file. These files are processed sequentially in the order they are listed. This is exactly like what happens when we pass multiple Sail files on the command line without a `.sail_project` file to define the module structure. A module can therefore be thought of as a sequence of Sail files that is treated as a single logical unit. As an example, we could add a third module to our above file, which is comprised of three Sail files and depends on A and B.

``` rouge
C {
  requires A, B
  files
    foo.sail,
    bar.sail,
    baz.sail
}
```

Note that comments and trailing commas are allowed, and we could optionally delimit the lists using `[` and `]`, like so:

``` rouge
C {
  // Require both our previous modules
  requires [A, B]
  /* Both types of Sail comments are allowed! */
  files [
    foo.sail,
    bar.sail,
    baz.sail,
  ]
}
```

If we wanted to we could define `C` in a separate file, rather than adding it to our previous file, and pass multiple project files to Sail like so:

``` rouge
sail simple_mod.sail_project new_file_with_C.sail_project
```

These will be treated together as a single large project file. A use case might be if you were defining an out-of-tree extension `Xfoo` for sail-riscv, you could do something like:

``` rouge
sail sail-riscv/riscv.sail_project src/Xfoo.sail_project
```

and the modules you define in `Xfoo.sail_project` can require modules from `riscv.sail_project`, and also vice-versa, although it makes less sense in this example.

### Working with Makefiles

The `--list-files` option can be used to list all the files within a project file, which allows them to be used in a Makefile prerequisite. As an example, to build the module examples in this very manual, we use the rule below to generate documentation indexes (which our Asciidoctor plugin consumes) for every `.sail` file within a project file.

``` rouge
.SECONDEXPANSION:

module_sail_doc/%.json: ../examples/%.sail_project $$(shell sail ../examples/%.sail_project -list_files)
    mkdir -p module_sail_doc
    sail --doc $(addprefix -doc_file ,$(shell sail $< --list-files)) --doc-embed plain --doc-bundle $(notdir $@) -o module_sail_doc $<
```

### Conditional compilation within modules

We can use *variables* in our project files to control either file inclusion within a module or to control whether a module requires another or not. A variable can even contain a sequence of modules, that can then be used in a require statement, as shown in the following example:

``` rouge
variable ARCH = A64
variable ARCH_MODULES = if ARCH == A64 then arch64_only else []

arch_prelude {
  files
    prelude.sail,
    if $ARCH == A32 then arch_xlen32.sail
    else if $ARCH == A64 then [
      arch_xlen64.sail,
      arch_xlen64_helpers.sail
    ] else error("Invalid value for ARCH")
}

arch64_only {
  requires arch_prelude
  files
    instructions64.sail
}

arch_instructions {
  requires arch_prelude
  files
    instructions.sail
}

arch_end {
  requires arch_instructions, $ARCH_MODULES
  files
    end.sail
}
```

### Optional and default modules

Modules can be marked as either `optional` or `default`. Default modules are those that form the base part of a specification, whereas optional modules are intended to implement extensions which may or may not be present. Default modules cannot require optional modules.

## The Sail Grammar

This appendix contains a grammar for the Sail language that is automatically generated from the [Menhir](https://gallium.inria.fr/~fpottier/menhir) parser definition.

[TABLE]

First, we need some lexical conventions:

- `ID` is any valid Sail identifier

- `OPERATOR` is any valid Sail operator, as defined in [Operators](#_operators).

- `TYPE_VARIABLE` is a valid Sail identifier with a leading single quote `'`.

- `NUMBER` is a non-empty sequence of decimal digits `[0-9]+`.

- `HEXADECIMAL_LITERAL` is `0x[A-Ba-f0-9_]+`

- `BINARY_LITERAL` is `0b[0-1_]+`

- `STRING_LITERAL` is a Sail string literal.

`$[ATTRIBUTE]` and `$LINE_DIRECTIVE` represent attributes and line directives. Examples of line directives would be things like `$include`, `$ifdef` and so on.

An attribute starts with `$[` and ends with `]`, and in between consists of an attribute name, optionally followed by some structured *attribute data*. This attribute data is similar in structure to JSON (except without null).

Line directives start with a leading `$`, followed by the directive name (following the same lexical rules as Sail identifiers), then one or more spaces, before proceeding to the end of the line. Everything between the identifier and the line ending is the line directive’s argument (with leading and trailing whitespace removed). If a line directive identifier is followed by a `{` it is a *structured line directive*, and can span multiple lines. It contains the same JSON-like attribute data as for attributes.

``` rouge
<separated_nonempty_list_trailing(SEP, ELEM)> ::= ELEM [SEP]
                                                | ELEM SEP <separated_nonempty_list_trailing(SEP, ELEM)>

<id> ::= ID
       | operator OPERATOR
       | operator -
       | operator |
       | operator ^
       | operator *

<op_no_caret> ::= OPERATOR
                | -
                | |
                | *
                | in

<op> ::= OPERATOR
       | -
       | |
       | *
       | in
       | ^

<exp_op> ::= OPERATOR
           | -
           | |
           | @
           | ::
           | ^
           | *

<pat_op> ::= @
           | ::
           | ^

<typ_var> ::= TYPE_VARIABLE

<tyarg> ::= ( <typ_list> )


<prefix_typ_op> ::= epsilon
                  | 2^
                  | -
                  | *

<postfix_typ> ::= <atomic_typ>

<typ_no_caret> ::= <prefix_typ_op> <postfix_typ> (<op_no_caret> <prefix_typ_op> <postfix_typ>)*

<typ> ::= if <infix_typ> then <infix_typ> else <typ>
        | <infix_typ>

<infix_typ> ::= <prefix_typ_op> <postfix_typ> (<op> <prefix_typ_op> <postfix_typ>)*

<atomic_typ> ::= <id>
               | _
               | <typ_var>
               | <lit>
               | dec
               | inc
               | <id> <tyarg>
               | register ( <typ> )
               | ( <typ> )
               | ( <typ> , <typ_list> )
               | { NUMBER (, NUMBER)* }
               | { <kopt> . <typ> }
               | { <kopt> , <typ> . <typ> }

<typ_list> ::= <typ> [,]
             | <typ> , <typ_list>

<kind> ::= Int
         | Nat
         | Type
         | Order
         | Bool

<kopt> ::= ( constant <typ_var> : <kind> )
         | ( <typ_var> : <kind> )
         | <typ_var>

<quantifier> ::= <kopt> , <typ>
             | <kopt>


<effect> ::= <id>

<effect_set> ::= { <effect> (, <effect>)* }
               | pure

<typschm> ::= <typ> -> <typ>
            | forall <quantifier> . <typ> -> <typ>
            | <typ> <-> <typ>
            | forall <quantifier> . <typ> <-> <typ>


<pat1> ::= <atomic_pat> (<pat_op> <atomic_pat>)*

<pat> ::= <pat1>
        | <attribute> <pat>
        | <pat1> as <typ>

<pat_list> ::= <pat> [,]
             | <pat> , <pat_list>

<atomic_pat> ::= _
               | <negative_lit>
               | <id>
               | <typ_var>
               | <id> ()
               | <id> [ NUMBER ]
               | <id> [ NUMBER .. NUMBER ]
               | <id> ( <pat_list> )
               | <atomic_pat> : <typ_no_caret>
               | ( <pat> )
               | ( <pat> , <pat_list> )
               | [ <pat_list> ]
               | [| |]
               | [| <pat_list> |]
               | struct [<id>] { <separated_nonempty_list_trailing(,, <fpat>)> }

<fpat> ::= <id> = <pat>
         | <id>
         | _

<lit> ::= true
        | false
        | ()
        | NUMBER
        | undefined
        | bitzero
        | bitone
        | BINARY_LITERAL
        | HEXADECIMAL_LITERAL
        | STRING_LITERAL

<negative_lit> ::= - NUMBER
                 | <lit>


<to_or_downto> ::= to
                 | downto

<loop_exp> ::= <id> from <exp> to <exp> by <exp> in <typ>
             | <id> from <exp> <to_or_downto> <exp> by <exp>
             | <id> from <exp> <to_or_downto> <exp>

<exp> ::= <exp0>
        | <attribute> <exp>
        | <exp0> = <exp>
        | let <letbind> in <exp>
        | var <atomic_exp> = <exp> in <exp>
        | { <block> }
        | return <exp>
        | throw <exp>
        | if <exp> then <exp> else <exp>
        | if <exp> then <exp>
        | match <exp> { <case_list> }
        | try <exp> catch { <case_list> }
        | foreach ( <loop_exp> ) <exp>
        | repeat [termination_measure { <exp> }] <exp> until <exp>
        | while [termination_measure { <exp> }] <exp> do <exp>

<prefix_op> ::= epsilon
              | 2^
              | -
              | *

<exp0> ::= <prefix_op> <atomic_exp> (<exp_op> <prefix_op> <atomic_exp>)*

<case> ::= <pat> => <exp>
         | <pat> if <exp> => <exp>
         | <attribute> ( <case> )

<case_list> ::= <case>
              | <case> ,
              | <case> , <case_list>

<block> ::= <exp> [;]
          | let <letbind> [;]
          | let <letbind> ; <block>
          | var <atomic_exp> = <exp> [;]
          | var <atomic_exp> = <exp> ; <block>
          | <exp> ; <block>

<letbind> ::= <pat> = <exp>

<atomic_exp> ::= <atomic_exp> : <atomic_typ>
               | config ID
               | <lit>
               | <id> -> <id> ()
               | <id> -> <id> ( <exp_list> )
               | <atomic_exp> . <id> ()
               | <atomic_exp> . <id> ( <exp_list> )
               | <atomic_exp> . <id>
               | <id>
               | <typ_var>
               | ref <id>
               | <id> ()
               | <id> ( <exp_list> )
               | sizeof ( <typ> )
               | constraint ( <typ> )
               | <atomic_exp> [ <exp> ]
               | <atomic_exp> [ <exp> .. <exp> ]
               | <atomic_exp> [ <exp> , <exp> ]
               | struct [<id>] { <fexp_exp_list> }
               | { <exp> with <fexp_exp_list> }
               | [ ]
               | [ <exp_list> ]
               | [ <exp> with <vector_update_list> ]
               | [| |]
               | [| <exp_list> |]
               | ( <exp> )
               | ( <exp> , <exp_list> )

<fexp_exp> ::= <atomic_exp> = <exp>
             | <id>

<fexp_exp_list> ::= <fexp_exp>
                  | <fexp_exp> ,
                  | <fexp_exp> , <fexp_exp_list>

<exp_list> ::= <exp> [,]
             | <exp> , <exp_list>

<vector_update> ::= <atomic_exp> = <exp>
                  | <atomic_exp> .. <atomic_exp> = <exp>
                  | <id>

<vector_update_list> ::= <vector_update> [,]
                       | <vector_update> , <vector_update_list>

<attribute_data_key_value> ::= ID = <attribute_data>
                             | STRING_LITERAL = <attribute_data>

<attribute_data> ::= { [<attribute_data_key_value> (, <attribute_data_key_value>)*] }
                   | NUMBER
                   | STRING_LITERAL
                   | ID
                   | true
                   | false
                   | [ [<attribute_data> (, <attribute_data>)*] ]

<attribute> ::= $[ATTRIBUTE ]
              | $[ATTRIBUTE <attribute_data> ]



<funcl_annotation> ::= private
                     | <attribute>
                     | <doc_comment>

<funcl_patexp> ::= <pat> = <exp>
                 | ( <pat> if <exp> ) = <exp>

<funcl_patexp_typ> ::= <pat> = <exp>
                     | <pat> -> <typ> = <exp>
                     | forall <quantifier> . <pat> -> <typ> = <exp>
                     | ( <pat> if <exp> ) = <exp>
                     | ( <pat> if <exp> ) -> <typ> = <exp>
                     | forall <quantifier> . ( <pat> if <exp> ) -> <typ> = <exp>

<funcl> ::= <funcl_annotation> <id> <funcl_patexp>
          | <id> <funcl_patexp>

<funcls> ::= <funcl_annotation> <id> <funcl_patexp_typ>
           | <id> <funcl_patexp_typ>
           | <funcl_annotation> <id> <funcl_patexp> and <funcl> (and <funcl>)*
           | <id> <funcl_patexp> and <funcl> (and <funcl>)*

<funcl_typ> ::= forall <quantifier> . <typ>
              | <typ>

<paren_index_range> ::= ( <paren_index_range> @ <paren_index_range> (@ <paren_index_range>)* )
                      | <atomic_index_range>

<atomic_index_range> ::= <typ>
                       | <typ> .. <typ>
                       | ( <typ> .. <typ> )

<r_id_def> ::= <doc_comment> <r_id_def>
             | <attribute> <r_id_def>
             | <id> : <paren_index_range> (@ <paren_index_range>)*

<r_def_body> ::= <r_id_def>
               | <r_id_def> ,
               | <r_id_def> , <r_def_body>

<param_kopt> ::= <typ_var> : <kind>
               | <typ_var>

<typaram> ::= ( <separated_nonempty_list_trailing(,, <param_kopt>)> ) , <typ>
            | ( <separated_nonempty_list_trailing(,, <param_kopt>)> ) constraint <typ>
            | ( <separated_nonempty_list_trailing(,, <param_kopt>)> )

<unbracketed_typaram> ::= <separated_nonempty_list_trailing(,, <param_kopt>)> constraint <typ>
                        | <separated_nonempty_list_trailing(,, <param_kopt>)>

<type_def> ::= type <id> <typaram> = <typ>
             | type <id> = <typ>
             | type <id> <typaram> -> <kind> = <typ>
             | type <id> : <kind> = <typ>
             | type <id> : <kind> [= config ID (. ID)*]
             | struct <id> = { <struct_fields> }
             | struct <id> <typaram> = { <struct_fields> }
             | enum <id> = <id> (| <id>)*
             | enum <id> = { <enum_comma> }
             | enum <id> with <enum_functions> = { <enum_comma> }
             | union <id> = { <type_unions> }
             | union <id> <typaram> = { <type_unions> }
             | bitfield <id> : <typ> = { <r_def_body> }

<enum_functions> ::= <id> -> <typ> , <enum_functions>
                   | <id> -> <typ> ,
                   | <id> -> <typ>

<enum_comma> ::= <id> [,]
         | <id> => <exp> [,]
         | <id> , <enum_comma>
         | <id> => <exp> , <enum_comma>

<struct_field> ::= <doc_comment> <struct_field>
                 | <attribute> <struct_field>
                 | <id> : <typ>

<struct_fields> ::= <struct_field>
                  | <struct_field> ,
                  | <struct_field> , <struct_fields>

<type_union> ::= private <type_union>
               | <attribute> <type_union>
               | <doc_comment> <type_union>
               | <id> : <typ>
               | <id> : { <struct_fields> }

<type_unions> ::= <type_union> [,]
                | <type_union> , <type_unions>

<rec_measure> ::= { <pat> => <exp> }

<fun_def> ::= function [<rec_measure>] <funcls>

<mpat> ::= <atomic_mpat> (<pat_op> <atomic_mpat>)*
         | <atomic_mpat> as <id>

<mpat_list> ::= <mpat> [,]
              | <mpat> , <mpat_list>

<atomic_mpat> ::= <negative_lit>
                | <id>
                | <id> [ NUMBER ]
                | <id> [ NUMBER .. NUMBER ]
                | <id> ()
                | <id> ( <mpat_list> )
                | ( <mpat> )
                | ( <mpat> , <mpat_list> )
                | [ <mpat_list> ]
                | [| |]
                | [| <mpat_list> |]
                | <atomic_mpat> : <typ_no_caret>
                | struct [<id>] { <separated_nonempty_list_trailing(,, <fmpat>)> }

<fmpat> ::= <id> = <mpat>
          | <id>

<mpexp> ::= <mpat>
          | <mpat> if <exp>

<mapcl> ::= <attribute> <mapcl>
          | <doc_comment> <mapcl>
          | <mapcl0>
          | <mapcl0> When <exp>

<mapcl0> ::= <mpexp> <-> <mpexp>
           | <mpexp> => <exp>
           | forwards <case>
           | backwards <case>

<mapcl_list> ::= <mapcl> [,]
               | <mapcl> , <mapcl_list>

<map_def> ::= mapping <id> = { <mapcl_list> }
            | mapping <id> : <typschm> = { <mapcl_list> }

<let_def> ::= let <letbind>


             | impure
             | pure

<extern_binding> ::= <id> : STRING_LITERAL
                   | _ : STRING_LITERAL

<externs> ::= STRING_LITERAL
            | { <separated_nonempty_list_trailing(,, <extern_binding>)> }
            | <pure_opt> STRING_LITERAL
            | <pure_opt> { <separated_nonempty_list_trailing(,, <extern_binding>)> }

<val_spec_def> ::= val STRING_LITERAL : <typschm>
                 | val <id> : <typschm>
                 | val <id> = <externs> : <typschm>
                 | val <id> : <typschm> = <externs>

<register_def> ::= register <id> : <typ>
                 | register <id> : <typ> = <exp>

<default_def> ::= default <kind> inc
                | default <kind> dec

<scattered_def> ::= scattered enum <id>
                  | scattered union <id> <typaram>
                  | scattered union <id>
                  | scattered function <id>
                  | scattered mapping <id>
                  | scattered mapping <id> : <funcl_typ>
                  | enum clause <id> = <id>
                  | function clause <funcl>
                  | union clause <id> = <type_union>
                  | mapping clause <id> = <mapcl>
                  | end <id>

<loop_measure> ::= until <exp>
                 | repeat <exp>
                 | while <exp>

<subst> ::= <typ_var> = <typ>
          | <id> = <id>

<instantiation_def> ::= instantiation <id>
                      | instantiation <id> with <subst> (, <subst>)*

<overload_def> ::= overload <id> = { <id> (, <id>)* }
                 | overload <id> = <id> (| <id>)*

<def_trailing_constraint_aux> ::= <scattered_def>

<def_constraint_aux> ::= constraint <typ>

<def_aux> ::= <fun_def>
            | <map_def>
            | FIXITY_DEF
            | <val_spec_def>
            | <instantiation_def>
            | <type_def>
            | <let_def>
            | <register_def>
            | <overload_def>
            | <default_def>
            | type constraint <typ>
            | $LINE_DIRECTIVE { [<attribute_data_key_value> (, <attribute_data_key_value>)*] }
            | $LINE_DIRECTIVE ...
            | termination_measure <id> <pat> = <exp>
            | termination_measure <id> <loop_measure> (, <loop_measure>)*

<def(AUX)> ::= private <def(AUX)>
             | <attribute> <def(AUX)>
             | <doc_comment> <def(AUX)>
             | AUX

<defs_post_trailing_constraint_list> ::= <def(<def_trailing_constraint_aux>)>
                                       | <def(<def_aux>)>
                                       | <def(<def_trailing_constraint_aux>)> <defs_post_trailing_constraint_list>
                                       | <def(<def_aux>)> <defs_list>

<defs_list> ::= <def(<def_constraint_aux>)>
              | <def(<def_trailing_constraint_aux>)>
              | <def(<def_aux>)>
              | <def(<def_constraint_aux>)> <defs_list>
              | <def(<def_trailing_constraint_aux>)> <defs_post_trailing_constraint_list>
              | <def(<def_aux>)> <defs_list>


```

## References

\[1\] Intel, “Intel 64 and IA-32 Architectures Software Developer’s Manual.” [software.intel.com/en-us/articles/intel-sdm](https://software.intel.com/en-us/articles/intel-sdm) , Dec. 2016.

\[2\] AMD, “AMD64 Architecture Programmer’s Manual Volume 1: Application Programming.” [support.amd.com/TechDocs/24592.pdf](http://support.amd.com/TechDocs/24592.pdf) , Oct. 2013.

\[3\] *Power ISA Version 3.0B*. OpenPOWER Foundation, 2017.

\[4\] L. Leighton, “The Libre-SOC Project.” EuroPython Society, 2021.

\[5\] *ARM Architecture Reference Manual (ARMv8, for ARMv8-A architecture profile)*. ARM Ltd., 2015.

\[6\] A. Reid, “Trustworthy Specifications of ARM v8-A and v8-M System Level Architecture,” 2016.

\[7\] MIPS Technologies, Inc., “MIPS64 Architecture For Programmers. Volume II: The MIPS64 Instruction Set.” Jul. 2005.

\[8\] MIPS Technologies, Inc., “MIPS64 Architecture For Programmers. Volume III: The MIPS64 Privileged Resource Architecture.” Jul. 2005.

\[9\] D. P. Mulligan, S. Owens, K. E. Gray, T. Ridge, and P. Sewell, “Lem: reusable engineering of real-world semantics,” in *Proceedings of ICFP 2014: the 19th ACM SIGPLAN International Conference on Functional Programming*, 2014, pp. 175–188, doi: 10.1145/2628136.2628143.

\[10\] “Lem implementation.” [github.com/rems-project/lem](https://github.com/rems-project/lem) , 2017.

\[11\] R. N. M. Watson *et al.*, “Bluespec Extensible RISC Implementation: BERI Hardware reference,” University of Cambridge, Computer Laboratory, UCAM-CL-TR-868, Apr. 2015. \[Online\]. Available: [www.cl.cam.ac.uk/techreports/UCAM-CL-TR-868.pdf](http://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-868.pdf).

\[12\] J. Heinrich, *MIPS R4000 Microprocessor User’s Manual (Second Edition)*. MIPS Technologies, Inc., 1994.

\[13\] MIPS Technologies, Inc., “MIPS32 Architecture For Programmers. Volume I: Introduction to the MIPS32 Architecture.” Mar. 2001.

\[14\] R. N. M. Watson *et al.*, “Capability Hardware Enhanced RISC Instructions: CHERI Instruction-Set Architecture (Version 5),” University of Cambridge, Computer Laboratory, UCAM-CL-TR-891, Jun. 2016. \[Online\]. Available: [www.cl.cam.ac.uk/techreports/UCAM-CL-TR-891.pdf](http://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-891.pdf).

------------------------------------------------------------------------

[1](#_footnoteref_1). ARM v8-A Architecture Specification: [github.com/meriac/archex](https://github.com/meriac/archex)

Last updated 2025-03-06 17:50:57 UTC

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
