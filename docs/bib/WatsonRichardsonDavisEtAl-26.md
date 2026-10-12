# CHERI C/C++ Programming Guide (living web edition) — snapshot

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-09-30  
**Project**: AIVHAI  
**Issue**: [#119](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/119)  
**Source**: https://github.com/CTSRD-CHERI/cheri-c-programming at commit `df9b68131d09afe4d694b3594a1f88b125cbcd65`; register entry `WatsonRichardsonDavisEtAl-26` in [`bibliography.md`](../bibliography.md)  
**Method**: the mdBook sources under `src/`, concatenated in `SUMMARY.md` order, unedited  
**Redistribute**: yes  

---

> **This is not the document.**  It is a snapshot of a web document, kept so that people and agents can search and read the text at the version cited.  Links, images, and navigation may be broken.  Where this text and the source disagree, the source at the pinned version is authoritative.  Copyright and licence are the original's: BSD-2-Clause, reproduced above as the licence requires.

## Licence (verbatim from the repository LICENSE)

```
Copyright (c) 2022 Robert N. M. Watson

This work was created by the University of Cambridge Department of Computer
Science and Technology with support from Innovate UK project 105694, "Digital
Security by Design (DSbD) Technology Platform Prototype".

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
```

{{#include ../../README.md:cover}}


# Introduction

This document is a brief introduction to the CHERI C/C++
programming languages, which employ CHERI's architectural capability
primitive to implement C/C++-language memory safety.
We explain the principles underlying these language variants, and their
grounding in CHERI's multiple architectural instantiations:
CHERI-RISC-V application cores, CHERIoT microcontrollers, and Arm's Morello.

We describe the most commonly encountered differences between these
dialects and C/C++ on conventional architectures, and where existing
software may require minor changes.
We document new compiler warnings and errors that may be experienced compiling
code with the CHERI Clang/LLVM compiler, and suggest how they may be addressed
through typically minor source-code changes.
We explain how modest language extensions allow selected software, such
as memory allocators, to further refine permissions and bounds on pointers,
as well as consistently print capability metadata to human-readable strings.

This guidance is based on our experience adapting the FreeBSD operating system
kernel and userspace, and applications such as the PostgreSQL database, nginx
web server, and Chromium web browser, to run in a CHERI C/C++ capability-based
programming environment.
It has also benefited from the considerable efforts taken by others to adapt
large-scale code bases such as the Linux kernel and OpenJDK.

We conclude by recommending further reading.


## Definitions

CHERI Clang/LLVM and LLD implement the following new language,
code-generation, and linkage models:

* **CHERI C/C++** are C/C++-language dialects tuned to requirements arising from
implementing all pointers using CHERI capabilities.
This includes all explicit pointers (i.e., those declared by the programmer)
and all implied pointers (e.g., those used to access local and global
variables).
For example, they diverge from C/C++ implementations on conventional
architectures by preventing pointers passed through integer type other
than `uintptr_t` and `intptr_t` from being dereferenced.
New Application Programming Interfaces (APIs) provide access to capability
features of pointers, including getting and setting their bounds, required
by selected software such as memory allocators.
The vast majority of C/C++ source code we have encountered requires little
or no modification to be compiled as CHERI C/C++.

* **Pure-capability machine code** is compiled code (or hand-written assembly)
that utilizes CHERI capabilities for all memory accesses &mdash; including
loads, stores, and instruction fetches &mdash; rather than integer addresses.
Capabilities are used to implement pointers explicitly described in the source
program, and also to implement implied pointers in the C execution
environment, such as those used for control flow.
Pure-capability machine code is not binary compatible with capability-unaware
code using integer pointers, not least due to the different size of the
pointer data type.

* **CHERI hybrid C/C++** are further language dialects in which only selected
pointers are implemented using capabilities, with the remainder implemented
using integers as on conventional architectures.
We have primarily used hybrid C in systems software that bridges between
environments executing pure-capability machine code and those running largely
or entirely non-CHERI-aware machine code.
While hybrid machine code has stronger binary compatibility with conventionally
generated code, it provides little or no memory protection, and its use is not
generally recommended.

The remainder of this document describes the CHERI C/C++ programming languages,
as mapped into pure-capability machine code; hybrid C/C++ will not be
considered further.


## Version history

The current web version is a living document being prepared for release as a
second edition in late 2025, based on five years of deployed experience with
hundreds of CHERI C/C++ developers working on various CHERI platforms
including Arm's Morello prototype, Microsoft's CHERIoT, Codasip's X730,
the University of Cambridge's CHERI-Toooba, and Capabilities Limited's
CVA6-CHERI platforms.

### 2020

We published the first version of the *CHERI C/C++ Programming Guide* in June
2020.

### 2025

This work-in-progress version of the *CHERI C/C++ Programming Guide* contains
the following changes:

 * Conversion to mdbook from LaTeX to enable a live web version.
 * Update cited articles and technical reports.
 * Better define, and discourage use of, CHERI Hybrid C/C++.
 * Include information on using CHERI C/C++ on a more diverse range of
   platforms, including Morello and CHERIoT, as well as work on arising
   CHERI-adapted OSes such as CHERI Linux and seL4.
 * Include information on printing capability values via `strfcap(3)` and
   `printf(3)`.
 * Discuss the goal of non-aliasing spatial and temporal memory safety, and
   explore when exceptions may be, or must be, delivered.
 * Document a subset of `malloc_revoke(3)` APIs controlling revocation for the
   system heap allocator.
 * Note that some behaviors, such as bounds precision and revocation behavior,
   are implementation defined.
 * Document expectations for in-memory capabilities, in particular the
   portability of `NULL` pointer values, and non-portability of any other
   assumptions.
 * Document that subobject bounds, as currently implemented, are
   opportunistic, and may not be precise.
 * Provide more detailed discussion of the limitations of the CHERI C/C++
   approach including with respect to integer-pointer type safety vs full
   pointer type safety, compile-time uncertainty on types, bounds imprecision,
   unions, stack temporal safety, and compiler optimizations.
 * Numerous minor editorial and formatting improvements.


# Background

CHERI extends conventional processor Instruction-Set Architectures (ISAs) with
support for *architectural capabilities*.
One important use for this new hardware data type is in the implementation
of safer C/C++ pointers and the code or data they point at.

Our 2019 technical report, [*An Introduction to
CHERI*](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-941.pdf), provides a
more detailed overview of the CHERI architecture, ISA modeling, hardware
implementations, and software stack[^1].
Our more recent 2025 article in IEEE Security and Privacy,
[*CHERI: Hardware-Enabled C/C++ Memory Protection at
Scale*](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10568212),
reviews recent research and results[^2].

[^1]: Robert N. M. Watson, Simon W. Moore, Peter Sewell, and Peter G. Neumann.
[An Introduction to
CHERI](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-941.pdf), Technical
Report UCAM-CL-TR-941, Computer Laboratory, September 2019.

[^2]: Robert N.M. Watson, David Chisnall, Jessica Clarke, Brooks Davis,
Nathaniel Wesley Filardo, Ben Laurie, Simon W. Moore, Peter G. Neumann,
Alexander Richardson, Peter Sewell, Konrad Witaszczyk, and Jonathan Woodruff.
[CHERI: Hardware-Enabled C/C++ Memory Protection at
Scale](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10568212),
IEEE Security & Privacy, vol. 22, no. 04, pp. 50-61, July-August 2024.


## CHERI capabilities

CHERI capabilities are twice the width of the native integer pointer type of
the baseline architecture: there are 128-bit capabilities on 64-bit platforms,
and 64-bit capabilities on 32-bit platforms.
Each capability consists of an integer (virtual) address of the natural size for
the architecture (e.g., 32 or 64 bit), and also additional metadata that is
compressed in order to fit in the remaining 32 or 64 bits of the capability
(see Figure 1 for an example; details
vary across underlying architectures and word sizes).
In addition, capabilities are associated with a 1-bit validity "tag" whose
value is maintained in registers and memory by the architecture, but is not
part of addressable memory.

<!--{=latex}\begin{comment}
In LaTeX, we want to use the bitbox figure below instead of the jpeg
image file, so we comment it out.
-->

![CHERI capability format illustration](capability-format.jpg)
*Figure 1: 128-bit CHERI Concentrate capability representation used in 64-bit CHERI-RISC-V as described in CHERI ISAv9: 64-bit address and metadata in addressable memory; and 1-bit out-of-band tag.*

<!--{=latex}
\end{comment}

\begin{figure}[b]
\hspace{2.5cm}
% Tag
\begin{subfigure}[t!]{0.1\textwidth}
\begin{bytefield}[bitwidth=3pt]{1}
% \bitheader[endianness=big]{~,~} \\
\begin{leftwordgroup}{1-bit tag}
\bitbox{1}{}
\end{leftwordgroup}
\end{bytefield}
\end{subfigure}
% Capability
\begin{subfigure}[t!]{0.1\textwidth}
\begin{bytefield}[bitwidth=3pt]{64}
\bitheader[endianness=big]{0,63} \\
\begin{rightwordgroup}{128-bit \\ in-memory \\ capability}
\bitbox{16}{perms} & \bitbox{3}{\color{lightgray}\rule{\width}{\height}} & \bitbox{15}{otype} & \bitbox{30}{bounds} \\
\bitbox[lrb]{64}{64-bit~address}
\end{rightwordgroup}
\end{bytefield}
\end{subfigure}
\caption{128-bit CHERI Concentrate capability representation used in
  64-bit CHERI-RISC-V: 64-bit address
  and metadata in addressable memory; and 1-bit out-of-band tag.}
\label{figure:cheri-capability-representation}
\end{figure}
-->

Each element of the additional metadata and tag of the capability contributes
to the protection model:


* **Validity tag**: The tag tracks the validity of a capability.
  If invalid, the capability cannot be used for load, store, instruction
  fetch, or other operations.
  It is still possible to extract fields from an invalid capability,
  including its address.

* **Bounds**: The lower and upper bounds are addresses restricting the
  portion of the address space within which the capability can be used for
  load, store, and instruction fetch.
  Setting a capability's address (i.e., where it points) within
  bounds will retain the capability's validity tag.
  Setting addresses out of bounds is subject to the precision limits of the
  bounds compression model (see below and [Out-of-bounds
  pointers](../impact/out-of-bounds-pointers.html)).
  Broadly speaking, setting addresses "nearly within" the capability's bounds
  will be "representable" in the model, and will preserve the validity tag.
  Out-of-bounds capabilities continue to authorize access only to memory
  within bounds.

* **Permissions**: The permissions mask controls how the capability can be
  used &mdash; for example, by authorizing the loading and storing of data and/or
  capabilities.

* **Object type**: If this value is not equal to the unsealed object type, the capability is "sealed" and
  cannot be modified or dereferenced, but can be used to implement opaque
  pointer types.
  This feature is not described further in this document, as it is primarily
  used to implement software compartmentalization rather than object-level
  memory protection.

<!-- XXXRW: Should talk about sealed entry capabilities here. -->

### Capability tagging

When stored in memory, valid capabilities must be naturally aligned &mdash; i.e.,
at 64-bit or 128-bit boundaries, depending on capability size &mdash; as that is
the granularity at which in-memory tags are maintained.
Partial or complete overwrites with data, rather than a complete overwrite
with a valid capability, lead to the in-memory tag being cleared, preventing
corrupted capabilities from later being dereferenced.

### Bounds precision

In order to reduce the memory footprint of capabilities, capability
compression is used to reduce the overhead of bounds so that the full
capability, including address, permissions, and bounds fits within 64 or
128 bits (plus the 1-bit out-of-band tag).
Bounds compression takes advantage of redundancy between the address
and the bounds, which occurs because a pointer typically falls within (or
close to) its associated allocation, and because allocations are typically
well aligned.
The compression scheme uses a floating-point representation, allowing high-precision bounds for small
objects, but requiring stronger alignment and padding for larger allocations
(see [Bounds alignment due to compression](../apis/bounds-alignment-due-to-compression.html)).
As a result, allocators handling large objects may define "spatial safety" as
providing non-aliasing rather than the guarantee of a trap, as allocation
bounds may not exactly align to architectural capability bounds.


## Architectural rules for capability use

The architecture enforces several important security properties on changes to
this metadata:

* **Provenance validity** ensures that capabilities can be used &mdash; for
  load, store, instruction fetch, etc. &mdash; only if they are derived via valid
  transformations of valid capabilities.
  This property holds for capabilities in both registers and memory.

* **Monotonicity** requires that any capability derived from another
  cannot exceed the permissions and bounds of the capability from which it was
  derived (leaving aside sealed capabilities, used for domain transition,
  whose mechanism is not detailed in this report).

### Root capabilities and capability derivation

At boot time, the architecture provides initial capabilities to the firmware,
allowing data access and instruction fetch across the full address space.
Additionally, all tags are cleared in memory.
Further capabilities can then be derived (in accordance with the monotonicity
property) as they are passed from firmware to boot loader, from boot loader to
hypervisor, from hypervisor to the OS, and from the OS to the application.
At each stage in the derivation chain, bounds and permissions may be
restricted to further limit access.
For example, the OS may assign capabilities for only a limited portion of the
address space to the user software, preventing use of other portions of the
address space.

### Intentionality

Similarly, capabilities carry with them *intentionality*: when a
process passes a capability as an argument to a system call, the OS kernel can
carefully use only that capability to ensure that it does not access other
process memory that was not intended by the user process &mdash; even though the
kernel may in fact have permission to access the entire address space through
other capabilities it holds.
This is important, as it prevents "confused deputy" problems, in which a more
privileged party uses an excess of privilege when acting on behalf of a less
privileged party, performing operations that were not intended to be
authorized.
For example, this prevents the kernel from overflowing the bounds on a
userspace buffer when a pointer to the buffer is passed as a
system-call argument.

### Capability atomicity

The hardware furthermore guarantees that capability tags and capability data is written atomically.
For example, if one thread stores a valid capability and another writes arbitrary data to the same location, it is impossible to observe the arbitrary data with the validity bit set.

### Formally verified groundings for memory safety

These architectural properties provide the foundation on which a
capability-based OS, compiler, and runtime can implement C/C++-language memory
safety.
They have been made precise and have been proved, with machine-checked proof,
to hold for the CHERI-MIPS architecture.[^1]

[^1]: Kyndylan Nienhuis, Alexandre Joannou, Thomas Bauereiss, Anthony Fox, Michael Roe, Brian Campbell, Matthew Naylor, Robert M. Norton, Simon W. Moore, Peter G. Neumann, Ian Stark, Robert N. M. Watson, and Peter Sewell. [Rigorous engineering for hardware security: Formal modelling and proof in the CHERI design and implementation process](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202005oakland-cheri-formal.pdf). In Proceedings of the 41st IEEE Symposium on Security and Privacy (Oakland 2020). San Jose, CA, USA, May 18-20, 2020.


# CHERI C/C++

The architectural-capability type can be used in a variety of ways by
software.
One particularly useful use case is in implementing *CHERI C/C++*.
In this model, all C/C++ language-visible pointer types, as well as any
implied pointers implementing vtables, return addresses, function pointers,
global variables, arrays of variadic-function arguments, and so on, are
implemented using capabilities with tight bounds.
This allows the architecture to imbue pointers with protection by virtue of
architectural provenance validity, bounds checking, and permission checking,
protecting pointers from corruption and providing strong spatial memory
safety.
In some execution environments, such as in CHERIoT and CheriBSD's CheriABI
process environment, capabilities are combined with efficient architectural
revocation features to enable strong heap temporal safety.


## The CHERI C/C++ run-time environment

CHERI C code executes within a capability-aware run-time environment
&mdash; whether "bare metal" with a suitable runtime, or in a richer, OS-based
process environment such as CheriABI (see [CheriABI](../cheriabi)) or
CHERIoT RTOS, which ensures that:

 * capabilities are context switched (if required);
 * tags are maintained by the OS virtual-memory subsystem (if present);
 * capabilities are supported in OS control operations such as
    debugging (as needed);
 * system-call arguments, the
run-time linker, and other aspects of the OS Application Binary Interface
(ABI) utilize capabilities rather than integer pointers;
 * the C/C++-language runtime implements suitable capability preservation
    (e.g., in `memcpy`) and restriction (e.g., in `malloc`); and
 * temporal safety is enforced by heap allocators (if supported).

CHERI is supported by a growing set of operating systems:

 * CheriBSD, the CHERI-extended version of the open-source FreeBSD operating
   system, CheriABI operates as a complete additional OS ABI.
   CheriABI is implemented in the style of a 32-bit or 64-bit OS personality,
   in that it requires its own set of suitably compiled system libraries and
   classes.
   Userlevel runs with referential, spatial, and temporal safety.
   At the time of writing, the kernel supports referential and spatial
   safety, but not temporal safety.
 * CHERI Linux also implements a pure-capability kernel and process
   environment modeled on CheriABI that support referential and spatial
   safety.
 * A number of bare-metal runtimes, such as newlib, and embedded operating
   systems, such as FreeRTOS (CheriFreeRTOS) and RTEMS (CHERI-RTEMS), have
   been adapted to support referential and spatial memory protection using
   CHERI.
 * seL4 has been updated (out of tree) to support referential and spatial
   memory protction using CHERI.
 * CHERIoT RTOS implements referential, spaital, and temporal memory
   protection using CHERI.

Outside of the OS and language runtime themselves, CHERI C/C++ require
relatively few source-code-level changes to C/C++-language software.
Exceptions to this rule of thumb typically take the form of compiler
toolchain, low-level C/C++ runtimes such as run-time linkers, and high-level
language runtimes that may (for example) include just-in-time compilers.

We explore the changes required to software in the remainder of this document.


## Referential, spatial, and temporal safety

Pure-capability C/C++ introduces a number of new types of protection not
present in compilation to conventional architectures:

* **Referential safety** protects pointers (references) themselves.
  This includes *integrity* (corrupted pointers cannot be dereferenced)
  and *provenance validity* (only pointers derived from valid pointers
  via valid manipulations can be dereferenced).

  When pointers are implemented using architectural capabilities, CHERI's
  capability tags and provenance validity naturally provide this protection.

* **Spatial safety** ensures that pointers may be used only to access memory
  within bounds of their associated allocation; dually, manipulating an
  out-of-bounds pointer will not grant access to another allocation.

  This is accomplished by adapting various memory allocators, including the run-time
  linker for global variables, thread-local variables, the stack allocator,
  and the heap allocator,
  to set the bounds on the capability implementing a pointer before returning
  it to the caller.
  Due to precision constraints on capability bounds, bounds on returned
  pointers may include additional padding, but will still not permit access to any
  other allocations (see [Bounds alignment due to
  compression](../apis/bounds-alignment-due-to-compression.html)).
  Monotonicity ensures that callers cannot later broaden the bounds to cover
  other allocations.

Referential safety and spatial safety are implemented in CheriBSD's and
CHERI Linux's kernels and pure-capability CheriABI execution environments, in
CHERIoT RTOS, CHERI-adapted seL4, and a number of CHERI-adapted embedded
operating systems including FreeRTOS and RTEMS.

* **Temporal safety** prevents a pointer retained after the release of its
  underlying allocation from being used to access its memory if that memory
  has been reused for a fresh allocation (e.g., after a fresh pointer to that
  memory has been returned by a further call to `malloc` after the
  current pointer passed to `free`).

  Heap temporal safety is accomplished by preventing new pointers being
  returned to a previously allocated region of memory while any prior pointers
  to that memory persist in application-accessible memory.
  Memory will be held in *quarantine* until any prior pointers have
  been revoked; then the memory may be reallocated.

  Architectural capability tags and revocation features allow intermittent
  *revocation sweeps* to accurately and efficiently locate and
  overwrite any capabilities implementing stale pointers.
  On application cores, architectural support includes MMU features to allow
  the tracking of "capability versions" of pages (a la loadside
  garbage-collection techniques), and on microcontroller cores, direct
  revocation bits may be stored directly in SRAM.
  Spatial safety ensures that pointers cannot be used to reference other
  memory, including other freed memory.

Temporal heap safety is implemented in CheriBSD's pure-capability CheriABI
execution environment running on Arm Morello and CHERI-RISC-V application
cores, and in CHERIoT RTOS running on CHERIoT microcontroller cores.


## Non-aliasing vs. trapping for memory safety

The CHERI architecture accepts a number of tradeoffs for performance reasons,
including imprecise bounds for spatial safety (to reduce pointer-size growth),
and quarantining for temporal safety (to mitigate revocation overheads).
CHERI C/C++ therefore adopt the following definitions and approximations:

 * **Referential safety** guarantees that a corrupted or reinjected pointer
   will be non-dereferenceable.
   This protection is guaranteed from the point of mis-manipulation (e.g., a
   partial overwrite in memory, manipulation using an inappropriate arithmetic
   operation, an attempt to violate monotonicity) but an architectural
   exception is not guaranteed to take place until a dereference (e.g., a
   load, store, or jump) is attempted.

 * **Spatial safety** guarantees non-aliasing between allocations: A pointer
   returned for one allocation will throw an architectural exception rather
   than permit out-of-bounds access to memory associated with another
   allocation.
   However, it is not guaranteed to throw an architectural exception if an
   out-of-bounds access would not access memory associated with another
   allocation.
   For example, non-trapping access may be permitted to padding after the end
   of a heap allocation for larger allocation sizes, due to bounds
   imprecision.
   It is the responsibility of the allocator to ensure that any non-trapping
   out-of-bounds access is *safe*.

 * **Temporal safety** guarantees non-aliasing between freed and current
   allocations: A pointer returned to a previously freed allocation will throw
   an architectural exception rather than permit use of the memory after
   reallocation.
   However, it is not guaranteed to throw an architectural exception if a use
   after free occurs before reallocation of that memory.
   For example, non-trapping access may be permitted to memory immediately
   after a call to `free()` but prior to asynchronous revocation or a further
   call to `malloc()` that reallocates the sam memory.
   It is the responsibility of the allocator to ensure that any non-trapping
   use-after-free access is *safe*.

These practical design choices have some important implications, including:

 * **Exception delivery semantics** are implementation defined, as: (a) bounds
   precision varies by underlying architecture; (b) memory allocators and
   revocation support may very by software runtime; and (c) compiler behavior,
   and in particular optimization, will vary in the presence of statically
   identifiable undefined behavior.
   Software developers should not make strong assumptions about whether an
   overflow on a particular size object may lead immediately to an exception.
   However, they may depend on dynamically enforced, deterministic,
   non-aliasing memory protection.

 * **Security arguments** are often easier to make in the presence of
   fail-stop behavior.
   Immediate trapping on a bounds or temporal-safety violation may make it
   easier to understand that code does not then proceed to other insecure
   behavior.
   Allocator authors may therefore choose to avoid aligning and padding
   strategies that unnecessarily introduce bounds imprecision.
   However, these tradeoffs do not weaken a security argument based on
   deterministic non-aliasing as the security guarantee, which tolerate
   continued execution beyond undefined behavior caused by a exception-free
   memory-safety bug.

 * **Debugabbility** is greatest when software fails stop close to the point
   of a bug occurring.
   CHERI will frequently ease debugging by ensuring trapping when aliasing
   takes place, as well as in many other situations.
   Deferred architectural exceptions until the point of dererence (for
   referential safety), or the point of potential alising (for spatial and
   temporal safety) do not weaken current debuggability, but also may not
   improve it in some situations.
   This is especially true when working with large or non-aligned memory
   allocations (for spatial safety) or rapid use-after-free without
   reallocation (for temporal safety).
   These design choices differ from those made in, for example, LLVM's address
   sanitizer, where rapid exception throwing is weighted more greatly than
   security mitigation.


# Impact on the C/C++ programming model

Several kinds of changes may be required by programmers; the extent to which
these changes impact a particular library or application will depend
significantly on its idiomatic use of C.
Our experience suggests that low-level system components such as run-time
linkers, debuggers, memory allocators, and language runtimes require a modest
but non-trivial porting effort.
Similarly, support classes that include, for example, custom synchronization
features, may also require moderate adaptation.
Other applications may compile with few or no changes &mdash; especially if they
are already portable across 32-bit and 64-bit platforms and are written in a contemporary C or C++ dialect.
In the following sections, we consider various kinds of programmer-visible
changes required in the CHERI C/C++ programming environment.
In many cases, compiler warnings and errors can be used to identify potential
issues compiling code as CHERI C/C++ (see [CHERI compiler warnings and errors](../compiler)).

<!--
\rwnote{Alex: Can we use the word "most" instead of "many"?}
-->


## Capability-related faults
<!--
\label{sec:faults}
-->

When architectural capability properties are violated, such as by an attempt
to dereference an invalid capability, access memory outside the bounds of a
capability, or perform accesses not authorized by the permissions on a
capability, this typically leads to a hardware exception (trap).
Operating-system kernels are able to catch this exception via a trap handler,
optionally delivering it to the run-time environment via OS-specific
mechanisms.

However, these exceptions are not guaranteed under the CHERI C/C++ model;
instead, a combination of hardware and software implement non-aliasing spatial
and temporal memory safety.
This means that pointers are never permitted to access memory from another
allocation, no matter how they are manipulated, but overruns into padding, or
access after free while memory is in quarantine, may still be permitted.
This topic is explored in greater detail in [Non-aliasing vs trapping memory
safety](../cheri-ccpp/nonaliasing-vs-trapping.md).

Further, the language-level behavior of CHERI C/C++ is considerably more
subtle: existing undefined behavior semantics in C are retained.
The compiler is free to assume that loads and stores will not trap (i.e., that
any program is free of undefined behavior), and may optimize under this
assumption, including reordering code.
Architectural traps occur when dynamic loads and stores are attempted, and
reordering could lead to potential confusing behavior for programmers.

In the CheriABI process environment, the operating system catches the hardware
exception and delivers a `SIGPROT` signal to the user process;
further information may be found in [CheriABI](../cheriabi).
In other environments, such as bare metal or under an embedded OS, behavior is
specific to those environments, as it will depend both on how architectural
exceptions are handled, and how those events are delivered to the C-language
stack.
Fail stop may be appropriate behavior in some environments, and is the default
behavior in CheriABI when `SIGPROT` is not handled.

<!--
\rwnote{We've opted to use the term "hardware exception" throughout, and
  mention "traps" only here.  This could cause confusion with respect to C++
  exceptions .. but perhaps less so than if we used the word "exception"
  unadorned.}
-->


## Pointer provenance validity
<!--
\label{sec:pointer_provenance_validity}
-->

CHERI C/C++ implement pointers using architectural
capabilities, rather than using conventional 32-bit or 64-bit integers.
This allows the provenance validity of language-level pointers to be
protected by the provenance properties of CHERI architectural capabilities:
only pointers implemented using valid capabilities can be dereferenced.
Other types that contain pointers, `uintptr_t` and `intptr_t`,
are similarly implemented
using architectural capabilities, so that casts through these types
can retain capability properties.
When a dereference is attempted on a capability without a valid tag &mdash;
including load, store, and instruction fetch &mdash; a hardware exception fires
(see [Capability-related faults](capability-faults.html)).
<!--
%\psnote{It would be better to exhaustively list them (is it just intptr\_t and uintptr\_t?) rather than this vague "such as"}
%\arnote{There are also cases such as C++11 strongly typed enums that use uintcap\_t as the underlying type, but we really don't need to mention this here. And I'm also not sure if we want to keep allowing that since enums should really be integer values only}
-->

On the whole, the effects of pointer provenance validity are non-disruptive to
C/C++ source code.
However, a number of cases exist in language runtimes and other
(typically less portable) C code that conflate integers and pointers that can
disrupt provenance validity.
In general, generated code will propagate provenance validity in only two
situations:

* **Pointer types** The compiler will generate suitable code to propagate
  the provenance validity of pointers by using capability load and store
  instructions.
  This occurs when using a pointer type (e.g., `void *`) or an
  integer type defined as being able to hold a pointer (e.g.,
  `intptr_t`).
  As with attempting to store 64-bit pointers in 32-bit integers on 64-bit
  architectures, passing a pointer through an inappropriate type will lead to
  truncation of metadata (e.g., the validity tag and bounds).
  It is therefore important that a suitable type be used to hold pointers.

  This pattern often occurs where an opaque field exists in a data structure
  &mdash; e.g., a `long_t` argument to a callback in older C code &mdash; that
  needs to be changed to use a capability-oblivious type such as `intptr_t`.

<!--
\psnote{I'm not sure this document has explained the ISA behavior concretely enough for this stuff to really make sense &mdash; the previous description was quite high-level.  Maybe somewhere it should be explicit that registers have tags, that load and store instructions must be via a capability, and that there are both capability and non-capability load and store instructions, with the former preserving tags (both ways) and the latter clearing them?}
-->

* **Capability-oblivious code** In some portions of the C/C++ runtime and
  compiler-generated code, it may not be possible to know whether memory is
  intended to contain a pointer or not &mdash; and yet preserving pointers is
  desirable.
  In those cases, memory accesses must be performed in a way that preserves
  pointer provenance.
  In the C runtime itself, this includes `memcpy`, which must use
  capability load and store instructions to transparently propagate capability
  metadata and tags.

  A useful example of potentially surprising code requiring modification for
  CHERI C/C++ is `qsort`.
  Some C programs assume that `qsort` on an array of data structures
  containing pointers will preserve the usability of those pointers.
  As a result, `qsort` must be modified to perform memory copies using
  pointer-based types, such as `intptr_t`, when size and alignment
  require it.


### Recommended use of C-language types
<!--
\label{sec:recommended-c-types}
-->

As confusion frequently arises about the most appropriate types to use for
integers, pointers, and pointer-related values, we make the following
recommendations:

* **`int`, `int32_t`, `long`, `int64_t`, ...**: These pure integer types
  should be used to hold integer values
  that will never be cast to a pointer type without first combining them with
  another pointer value &mdash; e.g., by using them as an array offset.
  Most integers in a C/C++-language program will be of these types.

* **`ptraddr_t`**: This is a new integer type introduced by CHERI C and should be
  used to hold addresses.
  `ptraddr_t` should not be directly cast to a pointer type for
  dereference; instead, it must be combined with an existing valid capability
  to the address space to generate a dereferenceable pointer.
  Typically, this is done using the `cheri_address_set(c, x)` function.

* **`size_t`, `ssize_t`**: These integer types should be used
  to hold the unsigned or signed lengths of regions of address space.
<!--
  \arnote{\sizet not necessary the same as unsigned `ptrdiff_t`.}
-->

* **`ptrdiff_t`**: This integer type describes the difference of indices
  between two pointers to elements of the same array, and should not be used
  for any other purpose.
  It can be added to a pointer to obtain a new pointer, but the result will
  be dereferenceable only if the address lies within the bounds of the
  pointer from which it was derived.

  <!--
  \note{Isn't that last sentence true of any combination?}{nwf}
  -->

  Less standards-compliant code sometimes uses `ptrdiff_t` when the
  programmer more likely meant `intptr_t` or (less commonly)
  `size_t`.
  When porting code, it is worthwhile to audit use of `ptrdiff_t`.

  <!--
  \note{Should we recommend that \sizet be used to hold lengths of
  allocations and \ptrdifft be used to talk about spans of
  address space (e.g., the offsets between two subobjects of an allocation)?  I feel
  like the recommendations here are not as concrete as I'd like.}{nwf}
  -->

* **`intptr_t`, `uintptr_t`**: These integer types should be
  used to hold values that may be valid pointers if cast back to a pointer
  type.
  When an `intptr_t` is assigned an integer value &mdash; e.g., due to
  constant initialization to an integer in the source &mdash; and the result is
  cast to a pointer type, the pointer will be invalid and hence
  non-dereferenceable.
  These types will be used in two cases: (1) Where there is uncertainty as to
  whether the value to be held will be an integer or a pointer &mdash; e.g., for an
  opaque argument to a callback function; or (2) Where it is more convenient
  to place a pointer value in an integer type for the purposes of arithmetic
  (which takes place on the capability's address and in units of bytes, as if
  the pointer had been cast to `char *`).

  The observable, integer range of a `uintptr_t` is the same as
  that of a `ptraddr_t` (or `ptrdiff_t` for `intptr_t`), despite the increased
  *alignment* and *storage* requirements.

* **`intmax_t`, `uintmax_t`**: According to the C standard, <!--
  \arnote{7.20.1.5 Greatest-width integer types}
  -->
  these integer types should be *capable of representing any value of any (unsigned) integer type*.
  In CHERI C/C++, they are not provenance-carrying and can represent the integer *range* of `uintptr_t`/`intptr_t`, but not the capability metadata or tag bit.
  As the observable value of `intptr_t`/`intptr_t` is the pointer address
  range, we believe this choice to be compatible with the C standard.

  Additionally, due to ABI constraints, it would be extremely difficult to change the width of these types from 64 to 129 bits.
  This is also true for other architectures such as x86: despite Clang and GCC supporting an `__int128` type, `intmax_t` remains 64 bits wide.

  We generally do not recommend use of these types in CHERI C/C++.
  However, the types may be useful in `printf` calls (using the `%j` format string width modifier) as the `inttypes.h` `PRI*` macros can be rather verbose.

* **`maxalign_t`**: This type is defined in C as *an object type whose alignment is the greatest fundamental alignment*
  and this includes capability types for CHERI C/C++.  <!--
  \arnote{C2x \S{}7.19.2} 
  % and in C++ as a \enquote{type whose alignment requirement is at least as great as that of every scalar type}\arnote{C++17 \S{}21.2.4p5}
  -->
  We found that some custom allocators use `sizeof(long double)` or `sizeof(uint64_t)` to align their return values.
  While this appears to work on most architectures, in CHERI C/C++ this must be changed to `alignof(maxalign_t)`.[^1]

* **`char *`, ...**: These pointer types are suitable for
  dereference, but in general <!--
  \psnote{that "in general" makes me wonder about the exceptions?}
  \arnote{The only exception I can think of is requiring `void *` due to bad API design (callback parameters, etc).}
  -->
  should not be cast to or from arbitrary integer
  values.
  Valid pointers are always derived from other valid pointers (including those cast to `intptr_t` or `uintptr_t`), and cannot be
  constructed using arbitrary integer arithmetic.

It is important to note that `uintptr_t` is no longer the same size as
`size_t`. This difference may require making some changes to
existing code to use the correct type depending on whether the variable
needs to be able store a pointer type. In cases where this is not obvious
(such as for a callback argument), we recommend the use of `uintptr_t`.
This ensures that provenance is maintained.

<!--
\pgnnote{The above section begs questions relating to what is the
  responsibility of programmers and what can be aided or managed by
  compilers.  Ideally, the latter would be preferable to requiring
  programmers to understand things are possibly beyond their so-called
  experience.}
-->

[^1]: It is important to use `alignof` instead of `sizeof` since many
common implementations, such as GCC and FreeBSD, define `maxalign_t` as a
`struct` and not a `union`.


### Capability alignment in memory

Because tags apply only to memory locations that are capability-aligned
and capability-sized,
unaligned storage of pointers will either generate a run-time
hardware exception (if a capability-aware load or store is performed), or discard the
tag (if a capability-oblivious memory copy is performed &mdash; e.g., using
`memcpy` to copy from an aligned location to an unaligned one).
One example of this is Berkeley DB (BDB) when used as an in-memory
implementation rather than as an on-disk database format.
Even when patched to use `memcpy` to copy objects stored as data, it
does not ensure sufficient alignment in its internal storage to preserve tags.
We therefore recommend against using BDB for this purpose.
While unaligned pointer use is uncommon in C programs, as data-structure
layouts are normally designed to keep them strongly aligned for performance
and atomicity reasons, any code depending on unaligned pointers will need
to be changed.

<!--
\amnote{Should we mention code that assumes that it is ok to go out of bounds
for optimization purposes? E.g., strcmp loading a word at a time?}
\psnote{yes}
-->


### Single-origin provenance
<!--
\label{sec:ambiguous-provenance}
-->

In the CHERI memory protection model, capabilities are derived from a single other
capability.
However, in C code, expressions may construct a new `intptr_t` value from more
than one provenance-carrying parent `intptr_t` &mdash; for example, by casting both a
pointer and a literal value to `intptr_t`-s, and then adding them. <!--
\psnote{That literal value wouldn't have a non-empty provenance, so this isn't the best example.   Maybe better to have something like \texttt{p+(q1-q2)} ?}
\psnote{More generally, there is a bit of a mismatch between this and our C provenance treatment of \cintptrt, which there is a plain integer type with no provenance &mdash; but which regains provenance in some cases when cast back to a pointer.  To ponder...}
-->
In that case, the compiler must decide which input capability provides the
capability metadata (bounds, permissions, ...) to be used in the output
value.
Consider for example the following code:

```{.clisting}
void *c1 = (void *)((uintptr_t)input_ptr + 1);
void *c2 = (void *)(1 + (uintptr_t)input_ptr);
uintptr_t offset = 1;
void *c3 = (void *)(offset + (uintptr_t)input_ptr);
```

In C with integer pointers, the values of `c1`, `c2`, and `c3` might be expected to have the
same value as `input_ptr`, except with the address incremented by one.
In CHERI C, each expression includes an arithmetic operation between provenance-carrying types.
While not visible in the source code, the constant `1` is promoted to a capability type, `uintptr_t`.
In the current implementation, the compiler will return the expected provenance-carrying result for cases `c1` and `c2` but not `c3`.[^2]

For `c1` and `c2`, the compiler sees that one of the sides is a non-provenance-carrying integer type that was promoted to `uintptr_t` and therefore selects the other operand as the provenance source.
It is not feasible to infer the correct provenance source for the third case, so the compiler will emit a warning.[^3]

The current behavior for such ambiguous cases is to select the left-hand-side as the provenance source, but we are considering making this an error in the future.

The recommended approach to resolve such ambiguous cases is to change the type of one operand to a non-provenance-carrying type such as `size_t`.
Alternatively, if the variable declaration cannot be changed, it is also possible to use a cast in the expression itself.

```{.clisting}
size_t offset_size_t = 1;
void *c3_good1 = (void *)(offset_size_t + (uintptr_t)input_ptr);

uintptr_t offset_uintptr_t = 1;
void *c3_good2 = (void *)((size_t)offset_uintptr_t + (uintptr_t)input_ptr);
```

We also provide a new attribute `cheri_no_provenance` that can be used to annotate variables or fields of type `intptr_t`/`uintptr_t` where the underlying type cannot be changed:

```{.clisting}
struct S {
    uintptr_t maybe_tagged;
    uintptr_t never_tagged __attribute__((cheri_no_provenance));
}
void test(struct S s, uintptr_t ptr) {
    void *x1 = (void *)(s.maybe_tagged + ptr); // ambiguous, currently uses LHS
    void *x2 = (void *)(s.never_tagged + ptr); // not ambiguous, uses RHS
}
```

<!--
\psnote{This doesn't really explain what `cheri_no_provenance` does?  And what it means when applied to other types?}\arnote{compiler error if it's not \cuintptrt. Will try to improve example later.}
-->

[^2]: Historically, the CHERI compiler would select the left-hand-most pointer in the expression as the provenance source.
While this model follows a single consistent rule, it can lead to surprising behavior if an expression places the provenance-carrying value to the right-hand-side.
In the example above, the value of `c1` would be a valid capability, but `c2` and `c3` would hold an untagged value (albeit with the expected address).

[^3]: We could add a data-flow-sensitive analysis to determine whether values are the result of promotion from a non-provenance-carrying type.
However, this would add significant complexity to the compiler and we have not seen many cases where this would have avoided changes to the source code.
<!--
\psnote{from a language-design POV, it'd be pretty horrid to have substantial semantics depend on just how smart one's analysis is}
\arnote{I agree. Even the current behavior is quite ugly, but at least it has measurable compatibility benefits.}
-->


## Capability representation in memory

Underlying implementations of CHERI are diverse, spanning 32-bit
microcontrollers (such as Microsoft's CHERIoT) to 64-bit server-class
processors (such as Arm's Morello).
CHERI C/C++ provide broad flexibility for implementations to represent
capability metadata in the ways most suitable to their individual
requirements.
One specific area in which CHERI implementations may differ is in the specific
in-memory representations of capabilities, due to not just different address
sizes, but also different tradeoffs around bounds compression, permissions,
and so on.

CHERI C/C++ in general expect that capabilities will be accessed via pointer
types, with operations such as dereferencing a pointer or performing pointer
arithmetic implemented by compiler-generated code.
Broadly, a capability consists of three parts: An address, inline metadata,
and a validity tag.
When stored in memory, CHERI capabilities are twice the size of the native
address type (e.g., 128 bits on 64-bit systems, and 64 bits on 32-bit
systems), in addition to an unaddressable tag bit.
There is one tag per capability aligned region of memory, and hence
capabilities must themselves be stored at capability alignment.

### Non-portability of the in-memory representation

To the greatest extent possible, it is desirable to write *portable CHERI
C/C++ code* that never directly interprets the in-memory representation of a
capability, with the exception of `NULL` values (see below).
Portable access to capability fields must be made using the [CHERI C APIs to
get and set capability
properties](../apis/retrieving-capability-properties.md).

However, there are cases in which writing *non-portable CHERI C/C++ code* is
both acceptable and essential, such as in the implementation of compilation,
linking, debugging, and tracing tools intentionally targeting specific target
architectures.
This is especially true when code will not be operating on the target
architecture itself, such as for cross-compilation, cross-linkage, and
cross-debugging, including in accessing core dumps.
In these cases, architecture specifications must be referenced in writing
encoding and decoding code, as there are significant variations between
platforms, and platforms themselves may also have parametizable elements to
their encoding.

### In-memory representation of NULL pointers

Conventional, integer-based architectures implement `NULL` pointers
integers with a value of `0`.
CHERI C/C++ similarly represents `NULL` as an all-zero capability value with
zero tag value, which is the only *portable* aspect of the in-memory
representation of a CHERI capability.

This has a number of implications, including that zero-filled memory with
zeroed tag values will be interpreted as being `NULL`-filled, as is the case
with conventional runtimes for C/C++.
This is particularly relevant for automatically initialized variable values
(such as global variables without specific initialization values), pre-zeroed
memory allocated by `calloc()`, or memory explicitly zeroed using
`memset(p, 0, n)`.
Similarly, storing `NULL` pointer values in memory will result in that memory
being zeroed.

The following code will always succeed:
```
	void *p = NULL;
	char zeroes[sizeof(p)];

	/* NULL == 0. */
	assert(p == 0);
	assert(cheri_address_get(p) == 0);

	/* All bytes in the NULL pointer are 0. */
	memset(zeroes, 0, sizeof(zeroes));
	assert(memcmp(&p, zeroes, sizeof(p)) == 0);
```


## Bounds

CHERI C/C++ pointers are implemented using capabilities that enforce lower and
upper bounds on access.
In the pure-capability run-time environment, those bounds are normally set to
the range of the memory allocation into which the pointer is intended to
point.
Because of capability compression, increased alignment requirements may apply
to larger allocations (see [Bounds alignment due to compression](../apis/bounds-alignment-due-to-compression.html)).

Bounds may be set on pointers returned by multiple system components including
the OS kernel, the run-time linker, compiler-generated code, system libraries,
and other utility functions.
As with violations of provenance validity, out-of-bounds accesses &mdash; including
load, store, and instruction fetch &mdash; trigger a hardware exception (see
[Capability-related faults](capability-faults.html)).


### Bounds from the compiler and linker

The compiler will arrange that language-level pointers to stack allocations have suitable
bounds, and that the run-time linker will return bounded pointers to global
and thread-local variables.
Bounds will typically be set based on an explicitly requested allocation size
(e.g., via the size passed to `alloca` or, for compiler-generated
code or linker-allocated memory, by the C type mechanism (e.g.,
`sizeof(foo)`), adjusted for precision requirements arising from
capability compression.
In some cases, such as with global variables allocated in multiple object
files, the actual size of the allocation may not be resolved until run time,
by the run-time linker.
These bounds will typically not cause observable changes in behavior &mdash; other than hardware exceptions when (accidentally) performing an out-of-bounds access.


### Bounds from the heap allocator

`malloc` will set bounds on pointers to new heap allocations.
In typical C use, this is not a problem, as programmers expect to access
addresses only within an allocation.

However, in some uses of C, there may be an expectation that memory access can
occur outside the allocation bounds of the pointer via which memory access
takes place.
For example, if an integer pointer difference `D` is taken between
pointers to two different allocations (`B` and `A`), and later
added to pointer `A`, the new pointer will have an address
within `B`, but permit access only to `A`.
This idiom is mostly likely to be found with non-trivial uses of `realloc` (e.g., cases where multiple pointers into a buffer allocated or reallocated by `realloc` need to be updated).
We note that the subtraction of two pointers from different
allocations is undefined behavior in ISO C, and risks mis-optimization from
breaking compiler alias analysis assumptions.
Further, *any* operation on the pointer passed to `realloc` is undefined upon
return.  Instead, we suggest that the programmer measure a pointer `P`'s
offset into an object `A` *prior to* `realloc` and derive new pointers
from the `realloc` result `B` and these offsets. (i.e., compute
*`B + (P - A)`* rather than
*`P + (B - A)`*).[^4]

[^4]: While it may seem that `A` remains available after `realloc`, our
revocation sweeps which enforce temporal safety may have atomically replaced
this with a non-pointer value.  The scalar value
*`D = P - A`* will naturally be preserved by revocation.


### Opportunistic subobject bounds

CHERI C/C++ also supports opportunistically restricting the
bounds when a pointer is taken to a subobject &mdash; for example, an array
embedded within another structure that itself has been heap allocated.
Subject to limitations arising from imprecise bounds (see
[Bounds precision](../background/cheri-capabilities.md#bounds-precision)),
this will prevent an overflow on that array from affecting the remainder of
the structure, improving spatial safety.

Subobject bounds are not enabled by default as they may require additional source code changes
for compatibility, but can be enabled using the `-Xclang -cheri-bounds=subobject-safe` compiler flag.
This is an active area of research, with consideration being given to enabling
a subset of subobject bounds checks by default in the future due to the
measurable security benefit and relatively low adoption friction.

One example of C code that requires changes for subobject bounds is the `containerof`
pattern, in which pointer arithmetic on a pointer to a subobject is used to
recover a pointer to the container object &mdash; for example, as seen in the
widely used BSD `queue.h` linked-list macros or the generic C
hash-table implementation, `uthash.h`.

In these cases, an opt-out annotation can be applied to a given type, field or variable
that instructs the compiler to not tighten bounds when creating pointers to subobjects.
We currently define three opt-out annotations that can be used to allow
existing code to disable use of subobject bounds:

**Completely disable subobject bounds**: It is possible to annotate a typedef,
record member, or variable declaration with:

```{.clisting}
__attribute__((cheri_no_subobject_bounds))
```

to indicate that the compiler should not tighten bounds when taking the address or a C++ reference. In C++11/C20 mode this can also be spelled as `[[cheri::no_subobject_bounds]]`.

```{.clisting}
struct str {
    /*
     * Nul-terminated string array -- pointers taken to this subobject will
     * use the array's bounds, not those of the container structure.
     */
    char               str_array[128];

    /*
     * Linked-list entry element -- because of the additional attribute,
     * pointers taken to this subobject will use the container structure's
     * bounds, not those of the specific field.
     */
    struct list_entry  str_le __attribute__((cheri_no_subobject_bounds));
} str_instance;

void
fn(void)
{
    /* Struct pointer gets bounds of str_instance. */
    struct str *strp = &str_instance;

    /* Character pointer gets bounds of the subobject, not str_instance. */
    char *c = str_instance.str_array;

    /* Struct pointer gets bounds of str_instance, not the subobject. */
    struct list_entry *lep = &str_instance.str_le;
}
```

**Disable subobject bounds in specific expressions**:
It is also possible to opt out of bounds-tightening on a per-expression
granularity by casting to an annotated type:

```{.clisting}
char *foo(struct str *strp) {
    return (&((__attribute__((cheri_no_subobject_bounds))struct str *)
        strp)->str_array);
}
```

**Use remaining allocation size**:
In certain cases, the size of the subobject is not known, but we still know that data
before the field member will not be accessed (e.g., variable size array members
inside structs).
Pre-C99 code will declare such members as fixed-size arrays, which will cause
a hardware exception if the allocation does not grant access to that many bytes.
[^5]
To use the remaining allocation size instead of completely disabling bounds
(and thus protecting against buffer underflows) the annotation:

```{.clisting}
__attribute__((cheri_subobject_bounds_use_remaining_size))
```

can be used.
When targeting C++11/C20:

```{.clisting}
[[cheri::subobject_bounds_use_remaining_size]]
```

is also supported.
Examples of this pattern include FreeBSD's `struct dirent`, which uses
`char d_name[255]` for an array that is actually of variable size, with
the containing allocation (e.g., of the heap) being sized to allow additional
space for array entries regardless of size in the type definition.
For example:

```{.clisting}
struct message {
    int     m_type;

    /*
     * Variable-length character array -- because of the additional
     * attribute, pointers taken to this subobject will have a lower bound
     * at the first address of the array, but retain an upper bound of the
     * allocation containing the array, rather than 252 bytes higher.
     */
    char    m_data[252]
                 __attribute__((cheri_subobject_bounds_use_remaining_size));
};
```

The use of subobject bounds imposes additional compatibility constraints on
existing C and C++ code.
While we have not encountered many issues related to subobject bounds in
existing code, it does slightly increase the porting effort.

## Effects of imprecise bounds

Subobject bounds are considered *opportunistic* because it may not be possible
to prevent aliasing within the bounds of a subobject pointer without
disturbing the binary layout policy for containing structures to permit
greater alignment and padding.
This particularly affects larger objects embedded within otherwise short
structures, such as large buffers with a short header.
Furthermore, variable-size structures pose a challenge because their size is
determined at run-time and the code requires explicit changes to the layout and
at the point of allocation to ensure representability.

This is an active area of research.
The problem of subobject bounds imprecision is also found in other programming
patterns, where an allocation is subdivided into multiple chunks, without any
cooperation from the allocator. We refer to these patterns as
intra-allocation bounds.

There are multiple approaches to address subobject bounds imprecision.
In general, precise bounds can be achieved by separately heap
allocating storage for each imprecise structure member, rather than embedding
them in the same allocation. This has trade-offs with respect to the added
complexity of managing an additional allocation, as well as additional indirection.
In some limited cases, ordering structure fields can also assist with bounds
precision for subobjects.

In the future, new compiler modes may be supported that allow fail stops to
occur if non-aliasing is not achieved, or to implement required alignment and
padding additions -- which may have significant memory overheads.
We are exploring potential improvements to compiler warnings and errors to
assist developers in debugging structure layouts that may lead to imprecise
bounds, a fail stop, or potentially unacceptable memory overhead.

Bounds precision of variable-size structures is determined by the offset
and size of the last member. This is more complicated to address with
compile-time warnings, because the size is not known.
Multiple approaches are possible in this case as well.
One option is to continue best-effort for variable size structs, specifically
for the variable-size member, to maximise source code compatibility.
A compiler option could control the exact bounds behaviour for variable-size
structure members, so that the programmer can opt-in to the fail-open behaviour.
It also possible to introduce annotations on variable-size members that specify
the maximum expected size, so that the compiler can insert the appropriate
amount of padding.

Finally, note that variable-size structures can only exhibit bounds aliasing on
the base, because the variable-size member is necessarily at the end of the
structure and, assuming the allocator is well-behaved, any rounding on the top
will only alias with extra padding space that is already part of the
representability padding for the whole allocation.

[^5]: If flexible arrays members are declared using the C99 syntax with empty
square brackets, the compiler will automatically use the remaining allocation
size.



### Other sources of bounds

Bounds may also be set by other parts of the implementation.
For example, the kernel may set bounds on pointers to new memory mappings (see
[The CheriABI POSIX process environment](../cheriabi)),
and the system library may set bounds on pointers
into returned buffers from APIs &mdash; e.g., `fgetln`.
More detailed information on how C/C++ code can set bounds can be found in
[C APIs to get and set capability properties](../apis).


### Out-of-bounds pointers
<!--
\label{sec:oob}
-->

<!--
\note{I feel like this section wants a reference to CHERI Concentrate?}{nwf}
-->

ISO C permits pointers to go only one byte beyond their original
allocation, but widely used code sometimes constructs transient pointer
values that are further out of bounds.
For example, `for` loops iterating over an array may increment a pointer
into the array by the array entry size before performing an overflow check
that terminates the loop.
This temporarily constructs an out-of-bounds pointer without an out-of-bounds
dereference taking place.

<!--
\nwfnote{In the straightforward case, tho, that still results in the pointer
being only one past the end of its allocation, doesn't it?}
-->

To support this behavior, capabilities
can hold a range of out-of-bounds addresses while retaining a valid
tag, and CHERI-enabled hardware performs bounds checks only on pointer
use (i.e., dereference), not on pointer manipulation.  Dereferencing
an out-of-bounds pointer will raise a hardware exception (see
[Capability-related faults](capability-faults.md)).
However, an out-of-bounds pointer can be
dereferenced once it has been brought back in bounds, by adjusting the
address or supplying a suitable offset in the dereference.

There is, however, a limit to the range of out-of-bounds addresses a capability can hold.
The capability compression model exploits redundancy between the pointer's address and
its bounds to reduce memory overhead (see [CHERI
capabilities](../background/cheri-capabilities.html)).
However, when a pointer goes out of bounds, this redundancy is reduced, and at
some point the bounds can no longer be represented within the capability.
The architecture prohibits manipulations that would produce such
a capability.
Depending on the architecture and context, this may lead to the
tag being cleared, resulting in an invalid capability, or in an immediate
hardware exception being thrown.
Attempting to dereference the invalid capability will fail in the same
manner as a loss of pointer provenance validity (see [Pointer provenance
validity](pointer-provenance-validity.html)).<!--
\psnote{Comment on whether that should immediately trap instead?} -->
The range of out-of-bounds addresses permitted for a capability is
a function of the length of the bounded region and the number of bits used for bounds in the capability representation.
With 27 bits of the capability used for bounds, 64-bit
CHERI-RISC-V provide the following guarantees:

* A pointer is able to travel at least 1/4 the size of the object, or
  2 KiB (2<sup>*floor*(*bounds_bits*/2)-2</sup>), whichever is greater,
  above its upper bound.

* It is able to travel at least 1/8 the size of the object, or 1 KiB
  (2<sup>*floor*(*bounds_bits*/2)-3</sup>), whichever is greater, below
  its lower bound.

In general, programmers should not rely on support for arbitrary out-of-bounds
pointers.  Nevertheless, in practice, we have found that the CHERI capability
compression scheme supports almost all in-the-field out-of-bounds behavior in
widely used software such as FreeBSD, PostgreSQL, and WebKit.


## Pointer comparison

In CHERI C/C++, pointer comparison considers only the
integer address part of a capability.
This means that differences in tag validity, bounds, permissions, and so on,
will not be considered when by C operators such as `==`, `<`, and `<=`.
On the whole, this leads to intuitive behavior in systems software, where,
for example, `malloc` adjusts bounds on a pointer before returning it to
a caller, and then expects an address-wise comparison to succeed when the
pointer is later returned via a call to `free`.  <!--
\nwfnote{I don't think I particularly like that example, since the thing `free`
is nominally comparing against is the bounded return from `malloc`.}
-->
However, this behavior could also lead to potentially confusing results; for
example:

* If a tag on a pointer is lost due to non-provenance-preserving
  `memcpy` (e.g., a `for` loop copying a sequence of bytes), the
  source and destination pointers will compare as equal even though the
  destination will not be dereferenceable.

* If a `realloc` implementation returns a pointer to the same
  address, but with different bounds, a caller check to see if the passed and
  returned pointers are equal will return `true` even though an access
  might be permitted via one pointer but not the other.

<!--
\psnote{I'm curious about the impact on compiler optimisation, where in the scope of \texttt{if (p==q)} compilers will often assume the two are interchangeable.  Comment on that?
 }
 \arnote{The choice between exact vs non-exact equals is made extremely late in code generation, it just chooses between emitting CEq and CExEq.
 Compiler analyses use a stricter definition of equality.
 In clang that should include some cases of taking provenance into account for alias information.}
-->

However, practical experience has suggested that the current semantics produce fewer
subtle bugs, and require fewer changes, than having comparison operators take
the tag or other metadata into account.[^6]

[^6]: The CHERI Clang compiler supports an experimental flag `-cheri-comparison=exact` that causes capability equality comparisons to also include capability metadata and the tag bit.

<!--
\arnote{default behavior=\texttt{-cheri-comparison=address}}
}
-->


## Implications of capability revocation for temporal safety

Heap temporal safety utilizes revocation sweeps, which, after some quarantine
period, replace in-register and in-memory capabilities to freed memory with
non-dereferenceable values.
For performance reasons, that replacement may be substantially deferred, or,
if there is little demand for fresh allocations, may never occur.
Pointer value replacement may also permit some instances of
a pointer to continue to be usable for longer than others, but the referenced
memory will not be reallocated or otherwise reused until all instances have been rendered unusable.
This model does permit non-exploitable *use-after-free* of heap memory,
but prohibits exploitable memory aliasing by disallowing *use-after-reallocation*.

A pointer's value after `free` is undefined, and so dereference is
an undefined behavior.
In practice, however, the value of a `free`-d pointer may still be
observed in a number of situations, including in lockless algorithms, which
may compare an allocated pointer to a freed one.

Our systems have a choice of replacement values for revoked pointers; all that
is required for correct temporal safety is that the replacement not authorize
access to memory.
Our prototype implementation clears the tag when replacing, as this
certainly removes authority and possibly simplifies debugging and
non-dereferencing operations, as the original capability bits are left behind.
For example, pointer equality checks that compare only the addresses of the two
pointers (and not their tag values) will continue to work as expected.  With
revocation performed this way, software making explicit use of tags must be
designed to tolerate capability tag clearing by revocation.

Unfortunately, tag-clearing risks type confusion if programmers intend to use
the capability tag to distinguish between integers and pointers in tagged
unions (we have so far generally discouraged this idea, but understand why it
may remain attractive).  Therefore, we have considered other options for
revocation, including tag-preserving *permission*-zeroing (but tag
preservation) and wholesale replacement with `NULL` (i.e., the untagged
all zero value).  These options may be more attractive for some software, and
would have different implications for the C/C++ programming model.

We anticipate that revocation will remain a tag-clearing operation by default,
as tag-clearing removes any risk of needlessly re-examining the capability in
later revocations.  However, it may be possible to allow coarse control over
revocation behavior either per process or by region of the address space.  In
the latter case, `mmap` may gain flags specifying which revocation
behavior is desirable for capabilities pointing *into* the mapped region
and/or `madvise` may gain flags controlling the revocation behavior of
capabilities *within* a target region.  Which of these or similar
mechanisms provide utility to software and can be offered at reasonable
performance remains an open question.


## Bitwise operations on capability types

In most cases bitwise operations &mdash; such as those used to store or clear flags
in the lower bits of pointers to well-aligned allocations &mdash; will result in the expected `uintptr_t` value being created.
However, there are some corner cases where the result may be a tagged (but out-of-bounds)
capability when an integer value is expected. <!--
\arnote{TODO: add an example. Maybe the mutex example checking low pointer bits + some alignment checks?}
-->
Dually, bitwise operations may also result in the loss of tags if intermediate results become unrepresentable (recall [Out-of-bounds pointers](out-of-bounds-pointers.html)).[^7]

Most bitwise operations on `uintptr_t` fall into one of three categories for which we provide
higher-level abstractions.

**Aligning pointer values**:
If the C code is attempting to align a pointer or check the alignment of pointers,
the following compiler builtins should be used instead:

* **`T __builtin_align_down(T ptr, size_t alignment)`**:
  This builtin returns `ptr` rounded down to the next multiple of `alignment`.
* **`T __builtin_align_up(T ptr, size_t alignment)`**:
  This builtin returns `ptr` rounded up to the next multiple of `alignment`.
* **`_Bool __builtin_is_aligned(T ptr, size_t alignment)`**:
  This builtin returns `true` if `ptr` is aligned to at least `alignment` bytes.

<!--
\rwnote{It would be nice if we had, and could document here, `cheri_` versions
  of these macros.}
\arnote{Probably best to use the `__builtin` versions since that also works for upstream clang.}
-->

One advantage of these builtins compared to `intptr_t` arithmetic is that they preserve the
type of the argument and can therefore remove the need for intermediate casts to `uintptr_t`.
Moreover, using these builtins allows for improved compiler diagnostics and can result in better code-generation compared to hand-written functions or macros.
We have submitted these builtins as part of the upstream Clang 10.0 release, so they can also be used for code that does not depend on CHERI.

<!--
\arnote{Should I include some of the documentation I wrote for upstream LLVM? (\url{https://clang.llvm.org/docs/LanguageExtensions.html\#alignment-builtins})}
-->

**Storing additional data in pointers**: <!--
\label{sec:low-pointer-bits}
-->
In many cases the minimum alignment of pointer values is known and therefore
programmers assume that the low bits (which will always be zero) can be
used to store additional data.[^8]
Unused high pointer bits cannot be used for additional metadata since toggling them causes a large change to the address field, and capabilities that are significantly far out-of-bounds cannot be represented (see
[Out-of-bounds pointers](out-of-bounds-pointers.html)).

The compiler-provided header `<cheri.h>` provides explicit macros for this
use of bitwise arithmetic on pointers.
The use of these macros is currently optional,[^9]
but we believe that they can improve readability compared to hand-written bitwise operations.
Additionally, the bitwise-AND operation is ambiguous since it can be used both to clear bits (which should return a provenance-carrying `uintptr_t`) and to check bits (which should return an integer value).
In complex nested expressions, these macros can avoid ambiguous provenance sources (see [Ambiguous provenance](../compiler/ambiguous-provenance.html)) since it shows the compiler which intermediate results can carry provenance.

* **`uintptr_t cheri_low_bits_clear(uintptr_t ptr, ptraddr_t mask)`**:
  This function clears the low bits of `ptr` in the same way as `ptr & ~mask`.
  It returns a new `uintptr_t` value that can be used for memory accesses when cast to a pointer.
  `mask` should be a bitwise-AND mask less than `_Alignof(ptr)`.
* **`ptraddr_t cheri_low_bits_get(uintptr_t ptr, ptraddr_t mask)`**:
  This function returns the low bits of `ptr` in the same way as `ptr & mask`.
  It should be used instead of the raw bitwise operation since it can never return
  an unexpectedly tagged value.
  `mask` should be a bitwise-AND mask less than `_Alignof(ptr)`.
* **`uintptr_t cheri_low_bits_or(uintptr_t ptr, ptraddr_t bits)`**:
  This function performs a bitwise-OR of `ptr` with `bits`.
  In order to retain compatibility with a non-CHERI architecture, `bits` should be less than the known alignment of `ptr`.
* **`uintptr_t cheri_low_bits_set(uintptr_t ptr, ptraddr_t mask, ptraddr_t bits)`**:
  This function sets the low bits of `ptr` to `bits` by clearing the low bits in  `mask` first.

**Computing hash values**:
The compiler will also warn when operators such as modulus or shifts are used on
`uintptr_t`. This usually indicates that the pointer is being used as the input to a hash
function or similar computations.
In this case, the programmer should not be using `uintptr_t` but instead cast the pointer
to `ptraddr_t` and perform the arithmetic on this type instead.

[^7]: Previous versions of the compiler used the capability offset (address
minus base) instead of the address for arithmetic on `uintptr_t`.
This often resulted in unexpected results and therefore we switched to using
the address in `uintptr_t` arithmetic instead.
The old offset-based mode may be interesting for garbage collected C where
addresses are less useful and therefore it can still be enabled by
passing `-cheri-uintcap=offset`.
However, this may result in significantly reduced compatibility with legacy C code.

[^8]: CHERI actually provides many more usable bits than a conventional architecture.
In the current implementation of 128-bit CHERI, any bit between<!--
\psnote{inclusive?} --> the least
significant and the 9th least significant bit may be toggled without causing
the tag to be cleared in pointers that point to the beginning of an allocation (i.e., whose *offset* is zero).  <!--
\psnote{This is confusing &mdash; not clearing the tag isn't the same as not destroying part of the pointer data...} -->
If the pointer is strongly aligned, further bits may be toggled without clearing the tag.
<!--
\nwfnote{But the macros only permit the use of the bottom 5.  We should say that somewhere.}
-->

[^9]: Until recently, not using these macros could result in subtle bugs at run time since pointer equality comparisons included the tag bit in addition to the address.


## Function prototypes and calling conventions

CHERI C/C++ distinguishes between integer and pointer types at an
architectural level, which can lead to compatibility problems with older C
programming styles that fail to unambiguously differentiate these types:

* **Unprototyped (*K&R*) functions**: Because pointers can no longer
  be loaded and stored without using capability-aware instructions, the
  compiler must know whenever a load or store might operate on a pointer
  value.
  The C-language default of using an integer type for function arguments when
  there is not an appropriate function prototype will cause pointer values to
  be handled improperly; this is also true on LP64 ABIs (e.g., most 64-bit
  POSIX systems).[^10]

  To avoid these problems, the CHERI Clang compiler emits a warning (`-Wcheri-prototypes`) by default when a function without a declared prototype is called.
  This warning is less strict than `-Wstrict-prototypes` and can be
  used to convert *K&R* functions that may cause problems.[^11]
  This should not be an issue for C code written in the last 20 years, but
  many core operating-system components can be significantly older.

* **Variadic arguments**: The calling convention for variadic functions
  passes all variadic arguments via the stack and accesses them via an
  appropriately bounded capability.
  This provides memory-protection benefits, but means that vararg functions
  must be declared and called via a correct prototype.

  Some C code assumes that the calling convention of variadic and non-variadic
  functions is sufficiently similar that they may be used interchangeably.
  Historically, this included the FreeBSD kernel's implementation of
  `open`, `fcntl`, and `syscall`.

<!--
  \rwnote{I wonder if we need to be more specific with an example here.}\arnote{TODO: Add example such as missing open() mode arguments?}
-->

[^10]: The ISO C23 standard makes function declarations with an
empty parameter list equivalent to a parameter list consisting of a single
`void`.

[^11]: If the *K&R* function is defined within the same file, the compiler can
determine the correct calling convention and will not emit a warning.


## Data-structure and memory-allocation alignment

CHERI C/C++ have stronger alignment requirements than C/C++ on conventional
architectures.
These requirements arise from two sources: that capabilities themselves must
be aligned at twice the integer architectural pointer width, and that
capability compression constrains the addresses that can be used for bounds
on larger objects.

<!--
\amnote{Is is worth mentioning compiler flags to warn on excessive padding?
  In particular, it seems that it is often the case that the ordering of
  struct elements that was devised for 32bit and 64bit architectures does
  not help much to avoid extra padding with capabilities. It more or less
  depends on how much the pointers are scattered in the struct definition.}
-->


### Restrictions in capability locations in memory
<!--
\label{sec:restricted-capability-locations}
-->

CHERI C/C++ constrain how and where pointers can be stored in memory in two
ways:

* **Alignment**: CHERI's tags are associated with capability-aligned,
  capability-sized locations in physical memory.
  Because of this, all valid pointers must be stored at such locations,
  potentially disrupting code that may use other alignments.

  On the whole, for performance and atomicity reasons, pointers are strongly
  aligned even on non-tagged architectures &mdash; however, when C constructs such
  as `__packed` are used, unaligned pointers can arise, and will not
  work with CHERI.
  While the compiler and native allocators (stack, heap, ...) will
  provide sufficient alignment for capability-based pointers, custom
  allocators may align allocations to `sizeof(intmax_t)` rather than
  `alignof(maxalign_t)`.

* **Size**: CHERI capabilities are twice the size of an integer able to
  describe the full address space.
  On 64-bit systems, this means that CHERI pointers will have a width of 128
  bits &mdash; while maintaining the arithmetic properties of a 64-bit integer
  address.
  C code historically embeds assumptions about pointer size in a number of forms,
  all of which will need to be addressed when porting to CHERI,
  including:

  * Assuming that a pointer will fit into the largest integer type.
  * Assuming that the number of bits in a pointer type is the same
    as the number of bits indexing the address space it can refer to.
  * Assuming that the number of bits in a pointer type is the same as the
    number of bits suitable for use in performing bit-wise manipulations of
    pointer values.
  * Assuming that pointers must either be 32 or 64 bits.
  * Assuming that aligning to `sizeof(double)` is sufficient to store any type.
  * Assuming that high bits of the pointer address can be used for
  additional metadata. This is not true on CHERI since toggling high bits of a
  pointer can cause it to be so far out of bounds that it is no longer representable
  due to the compression of pointer bounds. However, it is still possible to use
  the low bits for additional metadata (see [Bitwise operations on capability types](bitwise-operations.html)).

<!--
  \rwnote{Should there be more things in this list?}
-->

These portability problems will typically be found due to hardware exceptions
thrown on attempted unaligned accesses of capability values
(see [Capability-related faults](capability-faults.html)).
However, they can also arise in the form of stripped tag bits, leading to
invalid capabilities that cannot be dereferenced, if, for example, pointer
values are copied into inappropriately aligned allocations.


# Limitations to CHERI C/C++ memory safety

The idea of memory-safe C and C++ variants able to compile and run the vast
majority of extant code, despite research exploration for several
decades, remains surprising: Both languages have long histories of
catatrophic memory-safety vulnerabilities, leading to disastrous reputations
for their unsafety.
It is our experience in developing CHERI C and C++ that there are indeed
fundamental limits to the nature of improvements that can be made: Software
written in C and C++ expects significant type-system flexibility, making many
forms of static and dynamic enforcement difficult, and inherently embeds
assumptions that lead rapidly to "type confusion," a historically exploitable
condition that frequently allows minor memory corruption to be escalated into
arbitrary code execution.
However, it is also our practical experience that quite substantial headway
can be made in achieving strong memory safety for C and C++ despite this.

In this section we document and explore a number of constraints and
limitations to CHERI C and C++ memory safety.
Some originate from limitations in capturing language-level notions of type
safety (e.g., preventing integer-pointer confusion while not introducting
dynamic typing to differentiate pointer types from one another) when mapping
into CHERI's simpler capability model, some from CHERI's performance and
memory overhead(such as bounds compression), and others from limitations of
the currently implementations -- especially of the compiler and its
optimizations -- that we hope further research will rectify.
We explore:

 * Integer-pointer safety vs. pointer type safety
 * Compile-time uncertainty on regarding pointer types
 * Bounds imprecision, sub-object bounds, and custom allocators
 * Unions
 * Stack temporal safety
 * Compiler optimizations and undefined behavior

For each issue, we provide advice to developers and, where applicable,
information on current research directions that may address these issues in
the future.


## Integer-pointer safety vs. pointer type safety

CHERI C/C++ provide strong, dynamic differentiation of integer and pointer
values by virtue of capability tags: Integer values are not architecturally
dereferenceable.
CHERI C/C++ also strongly differentiate executable pointers (which will be
sealed and have execute permission) from data pointers (which will have load
and store permissions), which prevents execution of data as well as pointer
arithmetic on control-flow pointers.

However, tagged capabilities do not dynamically enforce C/C++-language types.
For example, casting from `struct foo *` to `struct bar *` is permitted
dynamically as long as the compiler accepts the cast, regardless of whether
that leads to unintended type confusion.
This is required because idiomatic C/C++ software has a strong expectation for
flexible casting, and enforcing these types breaks a significant proportion of
real-world software.

Common usage patterns requiring this sort of cast include object-oriented
programming styles used in C, and it is not clear what dynamic type system
might be both strong enough to provide useful vulnerability mitigation while
also being flexible enough to accept most software.
In C++, there are well defined rules for casting between classes and
subclasses, but those rules are extremely flexible and are not easily or
efficiently implemented architecturally.

CHERI permissions to prevent certain very narrow types of dynamic type
confusion that are essential to low-level memory safety: Specifically,
CHERI-enabled kernels and run-time linkers will by invariant prevent the
creation of code pointers with store privilege, or data pointers with execute
privilege.
Sealed capabilities also prevent undesired mutation of code pointers outside
of run-time linkers, just-in-time compilers, or the dynamic creation of
return addresses during function calls.

As such, while CHERI C/C++ preventing integer-pointer type, as well as certain
narrow forms of pointer-pointer type confusion, is incredibly valuable in
implementing memory safety, its benefits should not be confused with those of
full dynamic type safety.

**Advice to developers**: While many integer-pointer type confusions are
  strongly prevented in CHERI C/C++, pointer-pointer type confusions other
  than between code and data are not prevented.
  Given the current absence of static analysis tools addressing this problem,
  the best recourse will be defensive programming styles that avoid the
  opportunity for pointer-pointer type confusion, and careful tagging and
  checking of invariants dynamically.

**Ongoing research**: SRI/Cambridge have been exploring dynamic enforcement
  of language-level types using the architectural *otype* feature, but have
  yet to find a satisfactory middle ground between idiomatic type flexibility
  and strong vulnerability mitigation.
  Frequently, type errors of interest in C++ involve complex class hierarchies
  and inheritence, which are not directly mappable into a flat type space.
  New types of dynamic type enforcement, using *otype* or other capability 
  features, seem a promising area to explore in the future.

  In the CHERIoT design, sealing is frequently used for type safety between
  compartments to allow compartment state to be efficiently referenced without
  connoting access to that state, which was one of the fundamental design aims
  of the capability *otype* mechanism.
  This is driven via direct use of types in the source code, rather than being
  an automatic compiler feature.
  Similarly, we have used sealing in earlier explorations of how vtables in
  language runtimes (e.g., Java runtimes) can be used to improve robustness
  through explicit use of the *otype* mechanism.


## Compile-time uncertainty on pointer types

CHERI C/C++ provide strong dynamic differentiation of pointer and integer
values by virtue of the capability tag, which prevents their confusion at run
time.
For example, C code intended to increment a pure integer type will clear the
tag on a previously valid pointer, preventing its future dereference.
However, there are some necessary situations in which there is ambiguity --
perhaps required by the language specification, or perhaps just idiomatic use
-- and either integer or pointer values must be loaded or stored.
These fall into two common cases: Capability-oblivious copying, and explicit
type ambiguity.

### Capability-oblivious memory copying

Memory-copying is both a explicit and implied in the C and C++ languages, and
also a construct that programmers can implement.

The C `memcpy()` API copies a fixed quantity of data from one memory location
to another.
In CHERI C/C++, `memcpy()` is capability-oblivious: It is not, in general,
possible to know whether the originating memory should or does contain
capabilities, or whether the destination should or can accept their storage.
For example, a pointer to a structure that does contain a pointer field could
be cast to `void *`, losing that information.
Similarly, a pointer to an array of integer types, and no pointer fields, could
be cast to `void *`, losing that information.
While a manual copy of fields might do so using variables that do (or do not)
preserve tagged values, `memcpy()` implementations must be *capability
oblivious*: They copy any capabilities present, preserving rather than
stripping tags.

The situation is further complicated by compiler optimizations that may either
inline or outline `memcpy()`.
For example, a large structure assignment may appear to be type aware,
generating a series of suitably typed loads and stores, preserving or
stripping tagged values as appropriate, but the compiler is permitted to
replace that sequence with a call to `memcpy()` that will preserve tags even
if the source or destination types would not permit it.

Finally, there are many APIs in C, common libraries, and applications that are
in fact `memcpy()` implementations that must similarly be oblivious to dynamic
enforcement for the same reason.
For example, `qsort()` might be used on structures that contain pointers, and
therefore must preserve pointer types.
This imposes both a compatibility burden (custom memory-copying routines
require adaptation to preserve pointers) and also in effect causes capability
values to be propagated even if the C types themselves would not generally
cause that to take place.

**Advice to developers**: In general, C APIs such as `memcpy()`, and in fact
  structure assignment statements, can be assumed to always preserve pointers
  when they need to, but may also preserve them when not expected to.
  If it is important to prevent propagation, use the
  `cheri_perms_and()` API to strip the `CHERI_PERM_LOAD_CAP` permission before
  passing it to a routine that may perform a memory copy.
  In the CheriBSD kernel, which frequently needs to limit the flow of
  capabilities, `memcpynocap()` exists as a wrapper to this.

**Ongoing research**: SRI/Cambridge are continuing our research into the
  effects of compiler optimisations and when to constrain optimisations to
  better enforce protection properties.
  However, the tradeoffs here are tricky given the pracical goal of minimizing
  source-code disruption.
  It may be useful to add a new `memcpy_nocap()` API usable by both userlevel
  and the kernel.

### Intentional integer-pointer type ambiguity

Sometimes, programmers require an integer type that can be used to hold both
integer and pointer values, and furher, require that pointer arithmetic
performed on that type result in a dereferenceable pointer.
This is typically performed using the types `intptr_t` and `uintptr_t`, which
will frequently be found in software such as language runtimes, but also in
code implementing *callbacks* or similar programming behaviors where arbitrary
arguments or return values must be passed around by code not aware of the true
data types being used.
Stripping the tag on values calculated via these types will seriously disrupt
realworld source code.
When these types are used in CHERI C/C++, there are two important implications
with programmer impact:

  1. Capability-sized storage will be allocated, rather than that of the
     largest integer type, which can be confusing; i.e., `sizeof(intptr_t)`
     may not be the same as `sizeof(intmax_t)`.
     Further, if these types have been used extensively, perhaps in preference
     to other integer types, this can lead to a significant memory overhead
     beyond that seen just from increasing the size of pointer types.

  2. Instructions are therefore used that will preserve the tag on a
     capability dynamically by virtue of using arithetic instructions normally
     used only for pointer types.
     However, this means that CHERI C/C++ are not able to provide certain
     types of dynamic integer-pointer type-confusion prevention, as the types
     are inherently ambiguous.

     For example, while with non-`intptr_t` integer types, the tag will always
     be cleared when its arithmetic operations are applied to a pointer, this
     is not true when `intptr_t` is used for integers.
     If `intptr_t` is used extensively for integer types (e.g., as the atom
     type in a language runtime), then the opportunity for dynamic confusion
     is restored: arithmetic operations intended only to operate on integer
     values will also operate on pointers preserving the tag.

It is worth further noting that the C types `long` and `unsigned long` have
historically been used for these purposes, although that has been discouraged
for many years.
Code using `long` and `unsigned long` to hold pointer values in CHERI C/C++
will not preserve tags, and hence casting a pointer via `long` or `unsigned
long` will lead to the pointer no longer being dereferenceable.

**Advice to developers**: `intptr_t` and `uintptr_t` should be used only where
  essential to achieving the programming goals of either holding a pointer or
  integer in the same type (perhaps as an opaque argument), or to enable more
  rich forms of arithmetic on pointers.
  Where programers wish to compute on the address of pointers without provenance, `ptraddr_t` should be used to make this clear.
  Pointers can be unambiguously reconstructed using `ptraddr_t` computations and `cheri_address_set()`.
  `ptraddr_t` is currently under consideration for standardization as paper [P3744R0](https://isocpp.org/files/papers/P3744R0.html).
  `long` and `unsigned long` should never be used to hold pointers that must
  remain deferenceable.

**Advice to developers**: `ptraddr_t` should be used in place of `long`,
`unsigned long` or `uint64_t` where an integer type is required to hold
a virtual address.
As [previously introduced](../impact/recommended-use-c-types.md), `ptraddr_t`
is not dereferenceable on CHERI, and must be combined with a valid capability
to generate a dereferenceable pointer.


## Bounds imprecision, sub-object bounds, and custom allocators

CHERI capabilities employ bounds compression to fit both the lower and upper
bounds into a single address-sized word of metadata.
See [Bounds precision](../background/cheri-capabilities.md#bounds-precision)
for further details.

As a result, it is not possible to represent all possible combinations of
lower and upper bounds with a given address, leading to stronger alignment and
padding requirements for memory allocations.
The compiler, linker, and run-time environment are aware of these constraints,
and hence generally introduce necessary alignment and padding as required --
for example, by placing additional padding around some memory allocations to
ensure that more coarse bounds do not allow underruns or overruns to access
memory associated with other allocations.
See [Bounds alignment due to compression](../apis/bounds-alignment-due-to-compression.md#bounds-alignment-due-to-compression)
for further details.

There are, however, situations in which programmers must be explicitly aware
of this imprecise bounding behavior, including:

 - Optional use of sub-object bounds, which is currently considered
   *opportunistic protection* as sub-object bounds do not adjust structure
   alignment and padding for fields.
   This feaure is not currently enabled by default in the compiler due to
   these limitations.

 - Application-specific memory allocators, which require modest extensions to
   not just set bounds, but also ensure suitable alignment and padding such
   that non-aliasing can be enforced using CHERI bounds.

 - Sub-allocation patterns, where the result of a single call to `malloc()` is used
   to allocate two or more related but disjoint objects, possibly of different types.
   This case is different from custom allocators, because the intention is not to write
   a memory allocator, but rather to optimise the allocation of multiple
   related objects. Consider, for example, the contiguous allocation of an
   array and a structure that references the array. In this case, bounds must be
   set manually and considering precision will be necessary.

 - Other uses of manually set bounds in libraries and applications to limit
   the potential for underruns and overruns, such as in packet parsing, which
   must similarly take into account new alignment and padding requirements.

Where possible, the compiler will emit warnings in situations where sub-object
bounds cannot be guaranteed to provide precise spatial protection.

**Advice to developers**: When using sub-object bounds, additional padding and
  alignment may be required to ensure precise protection.
  In some situations, it may be more efficient to use external allocations
  pointed to by a primary allocation rather than embed sub-objects with large
  sizes and poor alignment within a larger strucure.
  Compiler warnings about limited precision should be observed.
  When implementing protecion in memory allocators, guidance provided in this
  document should be observed to ensure precise spatial safety is achieved.

**Advice to developers**: Sub-allocation patterns should be avoided. If multiple
  objects need to be allocated, the system allocator (or application-specific
  allocators) should be used to allocate each disjoint object separately, and
  should guarantee that the allocation is properly aligned and padded for
  representability. If sub-allocation can not be avoided, care must be taken to
  ensure that each sub-allocated object is placed at a representable boundary
  within the main allocation (note that this is platform-specific).
  Splitting a large allocation into multiple representable objects is not
  straightforward, see [Bounds alignment](../apis/bounds-alignment-due-to-compression.md#bounds-alignment-due-to-compression).

**Ongoing research**: SRI/Cambridge/SCI have ongoing research to improve the
  safety of sub-object bounds in the hopes of transitioning them from being
  "opportunistic" to being deterministically safe.
  This involves improvements to compiler analysis, the use of trapping
  bounds-setting instructions to ensure fail-closedd behavior, and optional
  support for additional alignment and padding.
  Early experiments with the CheriBSD kernel suggest that migrating to a
  deterministically safe sub-object bounds mode can be feasible with potentially
  modest disruption to the codebase (at least for the kernel). The main sources
  of friction appear to be Variable Length Arrays (VLAs). The toolchain can be
  extended to introduce padding to ensure sub-object representability; however,
  there are open questions to quantify the disruption to structure padding,
  whether this is acceptable and whether this can be automated.


## Unions

A significant benefit to introducing strong spatial and temporal safety in the
C and C++ programming languages is to reduce the opportunity for *type
confusion*, in which two different views (aliases) on the same memory region
allow that memory to be interpreted in different ways.
A classic example of this in widespread memory-corruption attacks is to store
to a memory region via characters (e.g., provided by network input) and then
to cause the application to load from the region interpreting it as a pointer
(e.g., as a control-flow pointer) making it possible to substantially
manipulate software including by achieving arbitrary code execution.
By implementing non-aliasing protection, pointers to one allocation of memory
cannot be used to implement type confusion with another pointer from a past or
future allocation of that memory.

Unions, however, are a C-language feature that intentionally allows multiple
interpretions of the same memory even within a single allocation.
While the precise impact is specific to its use, it is frequently the case
that unions may be used to reduce memory overhead or implement object
orientation, allowing code to interpret regions of memory as (for example)
both an array of characters and a control-flow pointer, enabling common attack
patterns.

CHERI's underlying robustness to integer-pointer type confusion is valuable in
mitigating such potential vulnerabilities, but as this does not provide strong
type safety, nor prevent other types of type confusion, ultimately this is
mitigation against attack techniques, rather than elimination of
vulnerability.

**Advice to developers**: Avoiding the use of unions in C will avoid such
  situations arising, especially in programming environments where the memory
  savings from such techniques may have little impact.
  Where unions must be used, attention can be paid to the types of confusion
  that might arise, as well as robust programming techniques to avoid type
  confusion.

**Ongoing research**: While SRI/Cambridge do not have current research in this
  space, it is easy to imagine introducing static limitations on union use,
  which could be evaluated for their impact on C/C++ code corpora to establish
  how disruptive this limitation might be at scale.


## Stack temporal safety

CHERI includes different temporal-safety mechanisms at different
microarchitectural scales.
In general, those mechanisms scale well to providing temporal safety for
services such as memory mappings and heap allocations, but do not perform
sufficiently well to enable generalized stack temporal safety able to address
use-after-function-return and use-out-of-scope vulnerabilities.
In the presence of compartmentalization support (e.g., for libraries in
CheriBSD or between compartments in CHERIoT RTOS), there may be stronger
protections preventing stack reuse or limiting the flow and reuse of stack
memory, but these are not provided within compartments.

**Advice to developers**: Existing sanitizers used to detect some
  use-after-function-return and use-out-of-scope bugs should be used when
  writing code intended to be robust on CHERI.
  As exploitation of stack temporal-safety vulnerabilities often involves the
  use of uninitialized stack values, compiler features automatically
  initialize stack variables can also play an important role in mitigation
  (see below).
  Finally, integer-pointer and other CHERI protections, such as sealing of
  code pointers, provide significant robustness against exploitation of such
  vulnerabilities -- but cannot be argued to strongly mitigate stack
  temporal-safety vulnerabilities in the same way that can be argued for heap
  allocations.

**Ongoing research**: The broader CHERI research community has been exploring
  a variety of mechanisms to provide probablistic or deterministic stack
  protections at varying costs, including concepts such as capability flow
  control and capability linearity.
  None have yet been deemed appropriate for widespread adoption, but we hope
  that at least one mechanism will proceed to maturity in due course.


## Compiler optimizations and undefined behavior

Many of CHERI's protections can be seen as an effort to determine new, and
safer, dynamic outcomes to undefined behavior specified in the C/C++
languages.
For example, CHERI's dynamic bounds checking and exception throwing replaces
the common (and specification-compliant) behavior of enabling arbitrary code
execution found in many C/C++ implementations.
There is, however, an important interaction with compiler optimizations:
Compilers are allowed to (and not infrequently do) assume that software will
not behave in undefined ways, and are permitted to optimize on that basis.
In this section, we explore several such cases that are important to be aware
of in understanding key limitations to the CHERI C/C++ approach.
This is an active area of research at SRI/Cambridge.

### Uninitialized local variables

In the C language, it is undefined behavior to depend on the value of an
uninitialized local variable, and bugs triggering this behavior are sometimes
exploitable vulnerabilities.
For example, an integer or pointer value may "shadow through" from a now free
stack frames, which could lead to misbehavior such as attacker-controlled
control flows.

CHERI does not, itself, prevent the use of uninitialized values, although it
does impose a number of protections that hamper exploitation (such as tagged
pointers, sealed control-flow pointers, spatial safety, and temporal safety).
Further, compartmentalization may limit the scope for stack reuse, preventing
(for example) application compartments from reusing stack space previously
used for privileged components such as the run-time linker and heap
allocators.
However, CHERI in isolation does not prevent the use of undefined values
exposed by uninitalized local variables,and it remains important to prevent or
mitigate these vulnerabilities in other ways.

**Advice to developers**: Compilers support both warnings regarding the use of
  unitialized local variables, as well as options to automatically zero (or
  otherwise initialize) uninitialized local variables.
  We strongly recommend that uninitialized local variables be considered a
  compile-time error or that automatic initialization be enabled, when using
  CHERI C/C++ for memory protection.

**Ongoing research**: The CHERI research community is actively exploring
  potential extensions to CHERI to detect or prevent undefined behavior.

### Uninitialized arguments and return values

As with software bugs involving uninitialized local variables, CHERI does not
directly prevent vulnerabilities from arising as a result of uninitialized
arguments or return values.
And, as with uninitialized local variabls, compilers are permitted to optimize
based on the assumption that no undefined behavior occurs in execution, and
may generate code that causes surprising resuls in the presence of improper
initialization.
CHERI indirectly affects the exploitability of those vulnerabilities by
virtue of pointer tagging, spatial safety, and temporal safety, but these
limited exploitation rather than preventing vulnerability.

**Advice to developers**: As with uninitialized local variables, compilers
  support warnings regarding the use of uninitialized arguments and failures
  to return values as defined by a function's prototype.
  We strongly recommend that uninitialized arguments and return values be
  considered compile-time errors.

### Out-of-bounds memory accesses

Compilers are, however, permitted to assume that undefined behavior does not
occur for the purposes of optimization, and may, for example, elide stores
that can be statically determined to be out of bounds.

For example, dynamic bounds checking on memory allocations frequently replaces
the specification-compliant corruption of other in-memory structures when a
buffer overflow occurs with a dynamic exception that, by default, terminates
an application.

Further, for a buffer with suitably scoped lifetime, not only may the store be
elided, but a later load may carry forward the expected value for being
loaded, despite the store not taking place.

This interacts importantly with the definitions of spatial and temporal safety
in CHERI, which are focused on *non-aliasing* rather than *precise
exceptions*.
If the compiler optimizes out an out-of-bounds store, then no CHERI exception
will be thrown dynamically.
Further, out-of-bounds loads may not only not throw an exception, but they may
see the value that was not stored.
CHERI's spatial safety is not violated, as no other object was corrupted.
However, this behavior may be surprising, and is a more broad example of how
memory-unsafe code may not fail stop, leading to further undefined execution
that could have surprising or insecure behavior.

**Advice to developers**: If memory-safety vulnerabilities are reported in
  software, it is important to validate the protection CHERI provides through
  testing and not just source-code inspection.
  This will help differentiate cases in which a clean "fail stop" is generated
  vs. those in which other undefined behavior may be reached, which must be
  analyzed in order to determine impact.

**Ongoing research**: The SRI/Cambridge team is actively investigating the
  impact of undefined behavior and compiler optimizations alongside CHERI
  memory protection.


# CHERI compiler warnings and errors

The CHERI Clang compiler includes many diagnostic warnings to identify code
that is incompatible with CHERI C/C++ or may result in behavioral
differences.
In many cases, a successful compilation that does not emit any CHERI-specific
warnings will result in a functional spatially-safe program.
However, some incompatibilities (e.g., memory allocators returning
insufficiently aligned pointers) cannot yet be diagnosed statically.
This section describes some of the more-commonly seen compiler warnings and
provides suggestions on how to change the source code to be compatible with
CHERI C/C++.
All these warnings are enabled when the `-Wall` compiler flag is
set.


## Loss of provenance

<!--
%\begin{compilerwarning}
%cast from provenance-free integer type to pointer type will give pointer that can not be dereferenced
%\end{compilerwarning}
-->

This common compiler warning<!--
\arnote{that should be an error by default?}
-->
is triggered when casting a non-capability type (e.g., `long`) to a pointer.
As mentioned in [Pointer provenance
validity](../impact/pointer-provenance-validity.html), the result of this cast is a `NULL`-derived capability with the address set to the integer value.
As any `NULL`-derived capability is untagged, any attempt to dereference it will trap.

Usually, this warning is caused by programmers incorrectly assuming that `long` is able to store pointers.
The fix for this problem is to change the type of the cast source to a provenance-carrying type such as `intptr_t` or `uintptr_t` (see [Recommended use of
C-language types](../impact/recommended-use-c-types.md)):

<!--
Need to use HTML formatting here for mdBook to get the highlight
colors in the code examples. The "id" attribute is required, because
we use that unique identifier in Pandoc to generate LaTeX highlight
formatting.
-->
<pre><code>char *example_bad(<mark id="BadParamTy" style="background-color: #EE918D">long</mark> ptr_or_int) {
    return strdup((const char *)ptr_or_int);
}
char *example_good(<mark id="GoodParamTy" style="background-color: #77DD77">intptr_t</mark> ptr_or_int) {
  return strdup((const char *)ptr_or_int);
}
</code></pre>


```{.compilerwarning}
<source>:2:17: warning: cast from provenance-free integer type to pointer type
will give pointer that can not be dereferenced [-Wcheri-capability-misuse]
  return strdup((const char *)ptr_or_int);
                ^
1 warning generated.
```

In some cases, this warning can be a false positive.
For example, it is common for C callback APIs take a `void *` data argument that is passed to the callback.
If this value is in fact an integer constant, the warning can be silenced by casting to `uintptr_t` first:

<!--
Need to use HTML formatting here for mdBook to get the highlight
colors in the code examples. The "id" attribute is required, because
we use that unique identifier in Pandoc to generate LaTeX highlight
formatting.
-->
<pre><code>void invoke_cb(void (*cb)(void *), void *);
void callback(void *arg);
void false_positive_example(int callback_data) {
    invoke_cb(&callback, (void *)callback_data); // warning
    invoke_cb(&callback, (void *)<mark id="SilenceProv" style="background-color: #77DD77">(uintptr_t)</mark>callback_data); // no warning
}
</code></pre>


```{.compilerwarning}
<source>:4:24: warning: cast from provenance-free integer type to pointer type
will give pointer that can not be dereferenced [-Wcheri-capability-misuse]
  invoke_cb(&callback, (void *)callback_data); // warning
                       ^
<source>:15:24: warning: cast to 'void *' from smaller integer type 'int'
[-Wint-to-void-pointer-cast]
  invoke_cb(&callback, (void *)callback_data); // warning
                       ^
2 warnings generated.
```

<!--
\nwfnote{The ``:15:24'' above should also be ``:4:24''?}
-->


## Ambiguous provenance

For arithmetic and bitwise binary operations between `uintptr_t`/`intptr_t`, the compiler can generally infer which side of the expression should be used as the provenance (and bounds) source.
However, as noted in [Single-origin provenance](../impact/single-origin-provenance.html), there are cases that are ambiguous as far as the compiler is concerned.

Consider for example a structure that holds a pointer and a small number of flags.
In this case the pointer is known to be aligned to at least 8 bytes, so the programmer uses the lowest 3 bits to store additional data:

```{.clisting}
typedef struct { uintptr_t data; } pointer_and_flags;
void set_ptr(pointer_and_flags *p, void *value) {
    p->data = (p->data & (uintptr_t)7) | (uintptr_t)(value);
}
void set_flags(pointer_and_flags *p, unsigned flags) {
    p->data = p->data | (flags & 7);
}
```

```{.compilerwarning}
<source>:3:40: warning: binary expression on capability types '__uintcap_t'
and 'uintptr_t' (aka '__uintcap_t'); it is not clear which should be used as
the source of provenance; currently provenance is inherited from the left-hand
side [-Wcheri-provenance]
    p->data = (p->data & (uintptr_t)7) | (uintptr_t)(value);
              ~~~~~~~~~~~~~~~~~~~~~~~~ ^ ~~~~~~~~~~~~~~~~~~
1 warning generated.
```

Unlike the compiler, the programmer knows that inside ```set_ptr``` capability metadata should always be taken from the `value` argument.
The suggested fix for this problem is fix is to cast the non-pointer argument to an integer type:

<pre><code>void set_ptr(pointer_and_flags *p, void *value) {
    p->data = <mark id="FixAmbig" style="background-color: #77DD77">(size_t)</mark>(p->data & (uintptr_t)7) | (uintptr_t)(value);
}
</code></pre>

<!--
\nwfnote{Not use cheri\_low\_bits\_set()?}
-->

<!--
\arnote{TODO: this section should have more examples.}
-->


## Underaligned capabilities

<!--
%\begin{compilerwarning}
%alignment (<N>) of '<type>' is less than the required capability alignment
%\end{compilerwarning}
-->

This warning is triggered when packed structures contain pointers.
As mentioned in [Restrictions in capability locations in memory](../impact/restrictions-in-capability-locations.md), pointers must always be aligned to the size of a CHERI capability (16 bytes for a 64-bit architecture).
This warning can be triggered by code that attempts to align pointers to at least 8 bytes (e.g., for compatibility between 32- and 64-bit architectures). For example:

<pre><code>struct AtLeast8ByteAlignedBad {
    void *data;
} __attribute__((packed, <mark id="BadAlignPacked" style="background-color: #EE918D">aligned(8)</mark>));
</code></pre>

```{.compilerwarning}
<source>:1:8: warning: alignment (8) of 'struct AtLeast8ByteAlignedBad' is
less than the required capability alignment (16) [-Wcheri-capability-misuse]
struct AtLeast8ByteAlignedBad {
       ^
<source>:1:8: note: If you are certain that this is correct you can silence
the warning by adding __attribute__((annotate("underaligned_capability")))
1 warning generated.
```

The simplest fix for this issue is to either increase alignment to be CHERI-compatible, or use a ternary expression to include `alignof(void *)`:

<pre><code><mark id="FixAlign1" style="background-color: #77DD77">#include &lt;stdalign.h&gt;</mark>
struct AtLeast8ByteAlignedGood {
    void *data;
} __attribute__((packed,aligned(<mark id="FixAlign2" style="background-color: #77DD77">alignof(void *) > 8 ? alignof(void *) : 8</mark>)));
</code></pre>

In the rare case that creating a potentially underaligned pointer is actually intended, the warning can be silence by adding a `annotate("underaligned_capability")` attribute:

<pre><code>struct UnderalignPointerIgnoreWarning {
    void *data;
} __attribute__((packed, aligned(4), <mark id="SilenceAlign" style="background-color: #77DD77">annotate("underaligned_capability")</mark>));
</code></pre>


# C APIs to get and set capability properties
<!--
\label{sec:cheri-apis}
-->

<!--
\rwnote{I wonder if we should talk more about permissions?  Perhaps not in
  this document, in which case possibly we should talk about them less?}
\amnote{If this is intended as a document to guide porting efforts perhaps
  we should mention them only as background info? If this becomes a summary
  of CHERI programming patterns then we probably want a section that talks
  about permissions as well.}
-->

CHERI C/C++ supports a number of new APIs to get and set capability
properties given a pointer argument.
Although most software does not need to directly manage capability properties,
there are some cases when application code needs to further constrain
permissions or limit bounds associated with pointers.
For example, high-performance applications may contain custom memory
allocators and wish to narrow bounds and permissions on returned pointers
to prevent overflows between its own allocations.


## CHERI-related header files

A set of compiler built-in functions provide access to capability properties
of pointers.
Two new header files (distributed as part of the CHERI Clang compiler)
provide access to further CHERI-related programming
interfaces including more human-friendly macro wrappers around the compiler
builtins, and also definitions of key CHERI constants:

* **`cheriintrin.h`**: defines interfaces to access and
  modify capability properties.
  It also defines constants for capability permissions that are portable
  across all implementations of CHERI.

* **`cheri.h`**: provides macros for slightly higher-level operations
  such as the manipulation of low pointer bits (see
  [Bitwise operations on capability types](../impact/bitwise-operations.html)).

When compiling for CheriBSD, the following header provides additional
constants relating to OS use of capabilities &mdash; for example, software-defined
permission bits:

* **`cheri/cheri.h`**: defines constants such as those used in the
  capability permission mask.

<!--
%`cheri/cheric.h`: defines interfaces to access and
%  modify capability properties.

\rwnote{This section may need updating once we've converged OS and compiler
  versions of cheri.h, and done any necessary header refactoring.}
-->


## Retrieving capability properties

The following APIs allow capability properties to be retrieved from pointers:

* **`ptraddr_t cheri_address_get(void *c)`**: Return the address of the capability `c`.

* **`ptraddr_t cheri_base_get(void *c)`**: Return the lower bound of capability `c`.

* **`size_t cheri_length_get(void *c)`**: Return the length of the bounds for the capability `c`.
  The base plus the length gives the upper bound on `c`'s address.

* **`size_t cheri_offset_get(void *c)`**: Return the difference between the address and the lower bound of the capability `c`.

* **`size_t cheri_perms_get(void *c)`**: Return the permissions of capability `c`.
  (See [Capability permissions](capability-permissions.html).)

* **`_Bool cheri_tag_get(void *c)`**: Return whether capability `c` has its
  validity tag set.

<!--
  \arnote{This returns the raw tag value, cheriintrin.h may also provide `cheri_is_valid` and `cheri_is_invalid`}
-->


## Modifying or restricting capability properties

The following APIs allow capability properties to be refined on pointers:

* **`void *cheri_address_set(void *c, ptraddr_t a)`**: Return a new capability with the same permissions and bounds as `c` with the address set to `a`.
This can be useful to re-derive a valid pointer from an address.

  `cheri_address_set` is able to set an address `a` that is
  outside of the current bounds of `c`.  The resulting capability
  is treated as an out-of-bounds pointer as described in [Out-of-bounds
  pointers](../impact/out-of-bounds-pointers.html).
  However, if the address `a` is not representable in the current
  bounds of `c` due to capability compression,
  `cheri_address_set` returns a capability without the tag bit set.

<!--
  %  This macro wraps the compiler built-in
  %  `__builtin_cheri_address_set`.
-->

* **`void *cheri_bounds_set(void *c, size_t x)`**: Narrow the bounds of capability
  `c` so that the lower bound is the current address (which may
  have been increased relative to `c`'s original lower bound), and its
  upper bound is suitable for a length of `x`.

  Note that the effective bounds of the returned capability may be
  wider than the range [`cheri_address_get(c)`,
  `cheri_address_get(c) + x`) due to capability compression (see
  [Bounds alignment due to
  compression](../apis/bounds-alignment-due-to-compression.html)),
  but they will always be a subset of
  the original bounds. <!--% of `c`.-->

* **`void *cheri_bounds_set_exact(void *c, size_t x)`**: Narrow the bounds of capability
  `c` so that the lower bound is the current address, and its
  upper bound is `cheri_address_get(c) + x`.
  This is similar to `cheri_bounds_set` but will raise a hardware exception if the resulting capability is not precisely representable instead of rounding the bounds.

<!--
\nwfnote{No mention of cheri\_bounds\_set\_exact?}
-->

* **`void *cheri_perms_and(void *c, size_t x)`**: Perform a bitwise-AND of capability
  `c`'s permissions and the value `x`, returning the new
  capability (see [Capability permissions](capability-permissions.html)).

<!--
  %  This macro wraps the compiler built-in
  %  `__builtin_cheri_perms_and`.
-->

* **`void *cheri_tag_clear(void *c)`**: Clear the tag on `c`, returning the
  new capability.

<!--
  % \note{Are the references to the `__builtin_` forms useful?  Do we
  % want to encourage their use or the `cheric.h` macros?}{nwf}
-->


## Capability permissions

<!--
\label{sec:capability_permissions}
-->

A number of capability permissions are available for use; only those relating
to CHERI memory protection are enumerated here:

* **`CHERI_PERM_EXECUTE`**: Authorize instruction fetch via this
   capability.

* **`CHERI_PERM_LOAD`**: Authorize data load via this capability.

* **`CHERI_PERM_LOAD_CAP`**: Authorize capability load via this capability.
  If the permission is not present, the tag on the loaded value
  will be silently cleared.

* **`CHERI_PERM_STORE`**: Authorize data store via this capability.

* **`CHERI_PERM_STORE_CAP`**: Authorize capability store via this capability.
  If the permission is not present, and the tag on the stored capability is
  valid, then a hardware exception will be thrown.

In addition to architectural permissions, CHERI capabilities have
software-defined permissions.
CheriBSD defines the following additional memory-protection-related
permission:

* **`CHERI_PERM_CHERIABI_VMMAP`**: A CheriABI-specific user
  permission that the kernel uses to authorize modifications to
  virtual-memory mappings.
  If the permission is not present, system calls that alter the contents
  or the presentation of memory mappings will reject the request.
  As this is a CheriBSD-specific permission, it is not defined in
  `cheriintrin.h` and requires inclusion of `cheri/cheri.h`.


## Bounds alignment due to compression

<!--
\label{sec:bounds_alignment}
-->

Bounds imprecisions may require a memory allocator to increase the alignment
of an allocation, or increase padding on an allocation, to prevent bounds from
spanning more than one object.
When the length of an object exceeds 2<sup>*floor*(*bounds_bits*/2)-1</sup> (i.e., 4 KiB for 64-bit CHERI-RISC-V), additional alignment requirements
apply to the lower and upper bounds.
The alignment required for allocations exceeding the minimum representable range (4 KiB for 64-bit CHERI-RISC-V) is 2<sup>*E*+3</sup> bytes, where
*E* is determined from the length, *l*, by
*E* = 52 - CountLeadingZeros(*l*[64: *floor*(*bounds_bits*/2)]).

<!--
\arnote{Is this too much detail?}
-->

<!--
%\jrtcnote{Do we want to clarify that this is a 65-bit length? One would naively
%expect it to be 64-bit and thus be off by one in all calculations. We should
%probably also steer people towards CRRL/CRAM regardless (and add cheri\_foo
%APIs for them).}
%\arnote{65-bit length is probably too much detail. But CRRL/CRAM now documented}
-->

Correctly computing the rounded size and minimum alignment for a given
allocation is non-trivial and may require many instructions to compute,
especially in the context of fast allocators such as the stack allocator.
Moreover, the architectural constants used for bounds precision differ across
architectures or their variations, and so alignment constraints also vary.
For example, the number of bits available for bounds differs between 32-bit and
64-bit CHERI-RISC-V, and also between 64-bit CHERI-RISC-V and Morello.

To avoid overly specific software knowledge of alignment requirements, and also to allow efficient calculation of alignment constraints during (for example) stack allocation, the CHERI ISA provides instructions that allow determining precisely representable allocations.
These instructions can be generated using compiler builtins that are provided by `cheriintrin.h`:

* **`size_t cheri_representable_length(size_t len)`**: returns the length that a capability would have after using `cheri_bounds_set` to set the length to `len` (assuming appropriate alignment of the base).

* **`size_t cheri_representable_alignment_mask(size_t len)`**: returns a bitmask that can be used to align an address downwards such that it is sufficiently aligned to create a precisely bounded capability.

The precisely representable base address can be computed using:

```{.clisting}
base = base & cheri_representable_alignment_mask(len);
```

When allocating from a contiguous buffer, the base needs to be aligned upwards instead of downwards.
This can be done with the following code:

```{.clisting}
size_t required_alignment(size_t len) {
    return ~cheri_representable_alignment_mask(len) + 1;
}
struct Buffer {
    void *data;
    size_t allocated;
};
void *allocate_next(struct Buffer *buf, size_t len) {
    char *result = buf->data + buf->allocated;
    result = __builtin_align_up(result, required_alignment(len));
    size_t rounded_len = cheri_representable_length(len);
    buf->allocated = (result + rounded_len) - (char *)buf->data;
    return cheri_bounds_set_exact(result, rounded_len);
}
```

Software written to use these compiler builtins, rather than encoding alignment
requirements directly, is more likely to be portable between
CHERI-RISC-V and Morello.


## Implications for memory-allocator design

One use case of these APIs is high-performance applications that contain custom memory
allocators and wish to narrow the bounds of returned pointers.
Two kinds of modifications are typically required:

* **Changes to alignment to allow for capabilities and bounds**:
  Changes relating to alignment fall into two categories.
  First, those required to allow pointers to be stored within allocations,
  which requires that allocations be aligned to the pointer width (128 bits).
  Second, further alignment changes will be required to ensure that bounds can
  be represented precisely.
  This requires suitably aligning both the bottom and top bounds to exclude
  any other live allocations, as described in [Bounds alignment due to
  compression](bounds-alignment-due-to-compression.html).
<!--
\arnote{May want to switch order of sections?}
-->

* **Reaching allocation metadata on `free`**:
  It is often the case that allocators utilize the value of the pointer passed
  to their custom `free` function to locate corresponding metadata &mdash;
  for example, by always placing that metadata immediately before the
  allocation, which would be outside of the allocation's bounds.
  Therefore, some additional work may be required to derive a pointer to the
  allocation's metadata via another global capability, rather than the one
  that has been passed to `free`.

These two concerns may interact: When a custom allocator places metadata at
the beginning of the allocation, care must be taken that the resulting pointer
is still strongly aligned.
While porting programs to run on CHERI, we found multiple sub-allocators
that used 8 bytes of metadata after the result from `malloc`.
This causes the resulting pointer to no longer be sufficiently aligned to
store capabilities without faulting or stripping tag bits.
<!--
\nwfnote{Does CHERI ISAv7 still fault in any of these scenarios?}
-->

Note that it is also possible to use the above APIs to validate inputs to
`free`, which is useful when the consumer of `free` is, for example,
an untrusted compartment or a component of a web browser that might be
influenced by an attacker. In such cases, `free` should validate that the
passed-in capability is tagged, is in-bounds, and points to a legitimate,
still-allocated allocation.  For allocators engaged in revocation for temporal
safety, concurrent revocation opens the door to TOCTTOU races within
`free`; additional care must be taken to prevent a double-`free`
using a stale pointer from freeing an object allocated after revocation.


## Printing capabilities from C

Capability pointers carry additional metadata that it can sometimes be useful
to print to a human readable string.
CHERI C/C++ defines a decoded string format for capabilities, which may be
accessed indirectly via existing C APIs such as `printf(3)`, `snprintf(3)`, or
directly via calls to the `strfcap(3)` function itself.


### Generating string representations of capabilities

```
ssize_t
     strfcap(char * restrict buf, size_t maxsize,
         const char * restrict format, uintcap_t cap);
```

The `strfcap(3)` API accepts multiple arguments:

 * `buf` is a target character buffer for the resulting generated string.
 * `maxsize` is the size of the target character buffer.
 * `format` is a string containing zero or more conversion specifiers or
   ordinary characters.
 * `cap` is the capability to decode.

The return value is the number of characters that would have been printed if
`size were unlimited, excluding the trailing nul terminator.
A negative value is returned on failure.

Various format specifiers, documented in the [CheriBSD `strfcap(3)` man
page](https://man.cheribsd.org/cgi-bin/man.cgi/strfcap.3), include various
individual field specifiers for capability metadata such as its address,
attributes, base address, length, offset, permissions, and so on.
The `%C` format string will print out capabilities with the following format
`%#xa [%P,%#xb-%%xt]%? %A`:

 * `%xa`: Hex formatted capability address
 * `%P`: Abbreviated human-readable capability permissions
 * `%xb`: Hex formatted capability base
 * `%xt`: Hext-formatted capability top address
 * `%A`: Textual representation of capability attributes, such as `invalid` or `sentry`

For example, the `strfcap(3)` output `0x130b60 [rwRW,0x130b60-0x130b64]`
describes a capability whose:

 * Capability address is `0x130b60`
 * Capability permissions are `rwRW` (can read and write both data and
   capabilities)
 * Capability base address is `0x130b60`
 * Capability top address is `0x130b64`
 * Has a valid tag
 * Is not sealed

The `strfcap(3)` man page should be referenced for full details.


### Printing capabilities with the printf(4) API family

When using the `printf(3)` family of APIs, the `#` qualifier to the `p` format
string will cause additional architecture-specific information to be printed
about a pointer.
In CHERI C/C++, this prints out capability metadata as rendered using
`strfcap(3)`'s `%C` format string.
For example, the following code fragment:

```
int foo;
...
        printf("%%p:\t%p\n", &foo);
        printf("%%#p:\t%#p\n", &foo);
```

Will print out the following output in CheriBSD's CheriABI:

```
%p:	0x130b60
%#p:	0x130b60 [rwRW,0x130b60-0x130b64]
```


# The CheriABI POSIX process environment

The CheriABI process environment implements a standard POSIX/UNIX API, but in
some areas there are changes to API semantics (e.g., in the handling of tagged
pointer values and I/O) or new functionality (such as relates to handling
capability-related faults).


## POSIX API changes

* **Writing and reading pointers via files**: In the CheriABI process
  environment, only untagged data (not tagged pointers) may be written to or
  read from files.
  If a region of memory containing valid pointers is written to a file, and
  then read back, the pointers in that region will no longer be valid.
  If a file is memory mapped, then pages mapped copy-on-write
  (`MAP_PRIVATE`) are able to hold tagged pointers, since they are
  swap-backed rather than file-backed, but pages mapped directly from the
  buffer cache (`MAP_SHARED`) are not.

* **Passing pointers via IPC**: In the CheriABI process environment, only
  untagged data, not tagged pointers, may be passed via various forms of
  message-passing Inter-Process Communication (IPC).
  Some existing software takes advantage of a shared address-space layout
  (via `fork`) to pass pointers to elements of shared data structures
  (e.g., entries in dispatch tables).
  This code must be converted to use indexes into tables or other lookup
  mechanisms rather than passing pointers via IPC.

* **`mmap` bounds**: In CheriABI, the `mmap` system
   call returns a bounded capability to the allocated address space.
   To ensure the capability does not overlap other allocations,
   lengths that would otherwise be unrepresentable are rounded up
   and padded with a new type of guard pages.
   These guard pages fault on access and may not be mapped over.
   They are unmapped when the rest of the mapping is unmapped.

* **`mmap` permissions**: The permissions of the capability
   returned by `mmap` are determined by a combination of the
   requested page protections and the capability passed as an address hint
   (or fixed address with `MAP_FIXED`).
   When using the pattern of requesting a mapping with `PROT_NONE`
   and then filling in sections (as is done in run-time linkers, VM host
   environments, etc), it is necessary to ensure that the initial
   capability has the right permissions.
   The `prot` argument has been extended to accept additional
   flags indicating the maximum permission the page can have so that a
   linker might request a reservation for a library with the permissions
   `(PROT_MAX(PROT_READ|PROT_WRITE|PROT_EXEC) | PROT_NONE)`, which
   would return a capability permitting loads, stores, and instruction
   fetch while mapping the pages with no (MMU) permissions.


## Handling capability-related signals

When a capability hardware exception fires, the operating system will map it
into the UNIX `SIGPROT` signal.
By default, this signal terminates the process, but the signal can be caught
by registering a `SIGPROT` handler.
When the signal handler fires, `siginfo.si_code` will be set to
describe the cause of the fault; available values, defined in
`signal.h`, include:

* **`PROT_CHERI_BOUNDS`**: Capability bounds fault &mdash; an out-of-bounds access was
  attempted.
* **`PROT_CHERI_PERM`**: Capability permission fault &mdash; the attempted access
  exceeded the permissions granted by a capability.
* **`PROT_CHERI_SEALED`**: Capability sealed fault &mdash; dereferencing a sealed
  capability was attempted.
* **`PROT_CHERI_TAG`**: Capability tag fault &mdash; dereferencing an invalid
  capability was attempted.


## Revocation APIs

Some CHERI run-time environments implement heap temporal safety, including
CheriBSD's CheriABI process environment and CHERIoT RTOS.
As described in [Referential, spatial, and temporal
safety](../cheri-ccpp/referential-spatial-temporal-safety.md), this is done on
the basis of quaranting with deferred (amortized) revocation of pointers that
must be performed before corresponding memory can be reallocated.

For CheriABI, the
[malloc_revoke(3)](https://man.cheribsd.org/cgi-bin/man.cgi/malloc_revoke)
APIs allowing interacting with, and control of, heap revocation.
These APIs relate only to quarantining and revocation of memory
allocated by the system heap allocator, `malloc(3)`.
Other memory allocators, such as the system memory-map allocator, may
independently implement temporal safety regardless of the heap allocator's
own configuration.
At the time of writing, these APIs are present only in CheriBSD.
See that manual page for complete documentation on available APIs.

We briefly consider two APIs: `malloc_revoke_enabled(3)`, which tests for
temporal safety support being enabled, and
`malloc_revoke_quarantine_force_flush(3)`, which triggers revocation and acts
as a barrier on its completion.

### Checking whether heap revocation is enabled

Heap allocator use of revocation is configurable by process.
If it is enabled in the current process, `malloc_revoke_enabled(3)` will
return true; otherwise, it will return false.

### Forcing revocation of outstanding freed pointers

Revocation of freed pointers is normally deferred, with the memory placed in
quarantine, for performance reasons.
`malloc_revoke_quarantine_force_flush(3)` flushes the current quarantine,
performing two functions:

 1. It initiates revocation of all memory quarantined when the API is called.
 2. It acts as a barrier to ensure that all pointers to memory allocations
    freed prior to the API being called have been revoked.

There are no guarantees made for frees occuring concurrent to, or after, the
call is made.

Use of this API is discouraged: It is provided primarily for testing,
debugging, and demonstration purposes, and can come with a very high
performance overhead.


# Further reading

## The CHERI ISA

The primary reference for the CHERI Instruction-Set Architecture (ISA) is the
ISA specification; at the time of writing, the most recent version is
[Capability Hardware Enhanced RISC Instructions: CHERI Instruction-Set
Architecture (Version
7)](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-927.pdf)[^1].

## An Introduction to CHERI

Our technical report, [An Introduction to
CHERI](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-941.pdf), provides a
high-level overview of the CHERI architecture, ISA modeling, hardware
implementations, and software stack[^2].

## C/C++ Memory Safety

Published at ASPLOS 2015, [Beyond the PDP-11: Architectural support for a
memory-safe C abstract
machine](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201503-asplos2015-cheri-cmachine.pdf)
describes idiomatic C and spatial memory protection[^3].

We published a paper on our memory-safe OS userspace and application suite,
[CheriABI: Enforcing Valid Pointer Provenance and Minimizing Pointer Privilege
in the POSIX C Run-time
Environment](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201904-asplos-cheriabi.pdf),
at ASPLOS 2019[^4].
We also released an [extended technical-report version of this
paper](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-932.pdf) that includes
greater implementation detail[^5].

We published [Cornucopia: Temporal Safety for CHERI
Heaps](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2020oakland-cornucopia.pdf) at Oakland 2020, explaining how to implement "sweeping revocation"
using virtual-memory acceleration[^6].

We published our paper, [Exploring C Semantics and Pointer
Provenance](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201901-popl-cerberus.pdf),
and the implications for software design, at POPL 2019; CHERI C was a case
study in the practical enforcement of capability provenance-validity
enforcement[^7].

[^1]: Robert N. M. Watson, Peter G. Neumann, Jonathan Woodruff, Michael Roe,
Hesham Almatary, Jonathan Anderson, John Baldwin, David Chisnall,
Brooks Davis, Nathaniel Wesley Filardo, Alexandre Joannou, Ben Laurie,
A. Theodore Markettos, Simon W. Moore, Steven J. Murdoch, Kyndylan Nienhuis,
Robert Norton, Alex Richardson, Peter Rugg, Peter Sewell, Stacey Son,
Hongyan Xia. [Capability Hardware Enhanced RISC Instructions: CHERI
Instruction-Set Architecture (Version
7)](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-927.pdf), Technical Report
UCAM-CL-TR-927, Computer Laboratory, June 2019.

[^2]: Robert N. M. Watson, Simon W. Moore, Peter Sewell, and Peter G. Neumann.
[An Introduction to
CHERI](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-941.pdf), Technical
Report UCAM-CL-TR-941, Computer Laboratory, September 2019.

[^3]: David Chisnall, Colin Rothwell, Robert N.M. Watson, Jonathan Woodruff,
Munraj Vadera, Simon W. Moore, Michael Roe, Brooks Davis, and
Peter G. Neumann. [Beyond the PDP-11: Architectural support for a memory-safe
C abstract machine](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201503-asplos2015-cheri-cmachine.pdf),
Proceedings of the Twentieth International Conference on Architectural Support
for Programming Languages and Operating Systems (ASPLOS 2015), Istanbul,
Turkey, March 2015.

[^4]: Brooks Davis, Robert N. M. Watson, Alexander Richardson,
Peter G. Neumann, Simon W. Moore, John Baldwin, David Chisnall,
Jessica Clarke, Nathaniel Wesley Filardo, Khilan Gudka, Alexandre Joannou,
Ben Laurie, A. Theodore Markettos, J. Edward Maste, Alfredo Mazzinghi,
Edward Tomasz Napierala, Robert M. Norton, Michael Roe, Peter Sewell,
Stacey Son, and Jonathan Woodruff. [CheriABI: Enforcing Valid Pointer
Provenance and Minimizing Pointer Privilege in the POSIX C Run-time
Environment](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201904-asplos-cheriabi.pdf).
In Proceedings of 2019 Architectural Support for Programming Languages and
Operating Systems (ASPLOS’19). Providence, RI, USA, April 13-17, 2019.

[^5]: Brooks Davis, Robert N. M. Watson, Alexander Richardson,
Peter G. Neumann, Simon W. Moore, John Baldwin, David Chisnall,
Jessica Clarke, Nathaniel Wesley Filardo, Khilan Gudka, Alexandre Joannou,
Ben Laurie, A. Theodore Markettos, J. Edward Maste, Alfredo Mazzinghi,
Edward Tomasz Napierala, Robert M. Norton, Michael Roe, Peter Sewell,
Stacey Son, and Jonathan Woodruff. [CheriABI: Enforcing valid pointer
provenance and minimizing pointer privilege in the POSIX C run-time
environment](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-932.pdf),
Technical Report UCAM-CL-TR-932, Computer Laboratory, January 2019.

[^6]: Nathaniel Wesley Filardo, Brett F. Gutstein, Jonathan Woodruff,
Sam Ainsworth, Lucian Paul-Trifu, Brooks Davis, Hongyan Xia,
Edward Tomasz Napierala, Alexander Richardson, John Baldwin, David Chisnall,
Jessica Clarke, Khilan Gudka, Alexandre Joannou, A. Theodore Markettos,
Alfredo Mazzinghi, Robert M. Norton, Michael Roe, Peter Sewell, Stacey Son,
Timothy M. Jones, Simon W. Moore, Peter G. Neumann, and Robert N. M. Watson.
[Cornucopia: Temporal Safety for CHERI
Heaps](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2020oakland-cornucopia.pdf).
In Proceedings of the 41st IEEE Symposium on Security and Privacy (Oakland
2020). San Jose, CA, USA, May 18-20, 2020.

[^7]: Kayvan Memarian, Victor B. F. Gomes, Brooks Davis, Stephen Kell,
Alexander Richardson, Robert N. M. Watson, and Peter Sewell. [Exploring C
Semantics and Pointer
Provenance](https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201901-popl-cerberus.pdf).
In Proceedings of the 46th ACM SIGPLAN Symposium on Principles of Programming
Languages (POPL), Cascais, Portugal, 13-19 January, 2019.


# Acknowledgements

We gratefully acknowledge the helpful feedback from our colleagues, including
Hesham Almatary, Ruben Ayrapetyan, Silviu Baranga, Jacob Bramley, Rod Chapman,
Paul Gotch, Al Grant, Brett Gutstein, Alfredo Mazzinghi, Alan Mycroft, and Lee
Smith.

This work was supported by the Defense Advanced Research Projects Agency
(DARPA) and the Air Force Research Laboratory (AFRL), under contracts
FA8750-10-C-0237 ("CTSRD"), HR0011-18-C-0016 ("ECATS"), and
FA8750-24-C-B047 ("DEC").
The views, opinions, and/or findings contained in this report are those of the
authors and should not be interpreted as representing the official views or
policies of the Department of Defense or the U.S. Government.

This work was supported in part by the Innovate UK project Digital Security by
Design (DSbD) Technology Platform Prototype, 105694.

This work was supported by part by the Engineering and Physical Sciences
Research Council (EPSRC) under UKRI3001: CHERI Research Centre, and under the
EPSRC REMS Programme Grant (EP/EP/K008528/1).

This project has received funding from the European Research Council (ERC)
under the European Union’s Horizon 2020 research and innovation programme
(grant agreement No 789108), ERC Advanced Grant ELVER.

We also acknowledge Arm Limited, HP Enterprise, and Google, Inc.
Approved for Public Release, Distribution Unlimited.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
