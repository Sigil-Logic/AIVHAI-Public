# compartmentalization(7), CheriBSD manual page — snapshot

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-10-09  
**Project**: AIVHAI  
**Issue**: [#232](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/232)  
**Source**: https://github.com/CTSRD-CHERI/cheribsd/blob/88f39900c32928d807dba245fba138808c666f34/share/man/man7/compartmentalization.7; register entry `Gao-26` in [`bibliography.md`](../bibliography.md)  
**Method**: mdoc source at the pinned commit rendered with `mandoc -T markdown`, unedited  
**Redistribute**: yes  

---

**Transliteration** of `share/man/man7/compartmentalization.7` at CTSRD-CHERI/cheribsd commit 88f39900c32928d807dba245fba138808c666f34, rendered with mandoc; the mdoc source is authoritative.

COMPARTMENTALIZATION(7) - Miscellaneous Information Manual

# NAME

**compartmentalization**,
**c18n** - linkage-based compartmentalization

# DESCRIPTION

This document contains instructions for using the linkage-based
compartmentalization (c18n) prototype.

Linkage-based compartmentalization contains a set of features provided by
rtld(1)
and other system libraries that enhances the security of existing
dynamically-linked pure-capability programs.

A new process inherits the compartmentalization setting of its parent.
To enable c18n for all new processes across the entire system, run

	sysctl security.cheri.lib_based_c18n_default=1

To override this and permanently enable or disable c18n for a particular
executable, use the
elfctl(1)
tool to write the setting into the executable.

To override this and temporarily enable or disable c18n for a particular
executable, run

	proccontrol -m cheric18n -s enable *executable*

or

	proccontrol -m cheric18n -s disable *executable*

as appropriate.

Overriding this still are the environment variables
`LD_COMPARTMENT_ENABLE`
and
`LD_COMPARTMENT_DISABLE`.
If both environtment variables are set, c18n is disabled.
Note that environment variables are not reliably inherited when processes fork.

## COMPARTMENT TRANSITION TRACING

Compartment transitions can be traced with the
ktrace(1)
facility.
To generate a trace, set the environment variable
`LD_UTRACE_COMPARTMENT`
and invoke the executable with
ktrace(1).

**CAUTION:**
Compartment transition tracing is only intended for debugging and analysis
purposes.
Turning it on will reduce security.

## COMPARTMENT TRANSITION OVERHEAD SIMULATION

To simulate the overhead of making a system call during each compartment
transition, set the environment variable
`LD_COMPARTMENT_OVERHEAD`
and invoke the executable.
Each compartment transition will then make a
getpid(2)
system call.

**CAUTION:**
Compartment transition overhead simulation is only intended for performance
analysis purposes.
Turning it on will reduce security.

## MORELLO BENCHMARK ABI VARIANT

The Morello benchmark ABI variant of the runtime linker also supports c18n.
Note that environment variables recognized by this variant need to be prefixed
with LD\_64CB\_ instead of LD\_.

**NOTE:**
Because the purecap variant uses some of Morello's architectural features that
are unavailable under the benchmark ABI, the benchmark ABI variant is not a
mere translation of the purecap variant but has a slightly different
implementation.
The best effort has been made to ensure that such a divergence
does not bias performance estimates under almost all circumstances.

# COMPATIBILITY

*	Calling
	vfork(2)
	is identical to calling
	fork(2),
	that is, no memory sharing will take place between the parent and child
	processes.

*	Calling
	rfork(2)
	with flags
	`RFMEM`
	or
	`RFSIGSHARE`
	will return -1.

*	sigaltstack(2)
	does not work as expected.
	This impacts some applications that use an alternative stack to handle
	stack-overflow exceptions.

*	getcontext(3),
	setcontext(3),
	and related functions do not work as expected.
	This impacts certain threading and coroutine libraries.

# SECURITY

The Trusted Computing Base (TCB) consists of the OS kernel, dynamic linker,
C/C++ runtime, threading library, and a few highly-privileged standard library
functions.
It is integrated into
rtld(1),
the
Standard C&#160;Library (libc, &#45;lc),
the
library &#8220;libsys&#8221;,
the
1:1 Threading Library (libthr, &#45;lthr),
and various C++ runtime libraries.
The startup code linked into every executable that executes prior to
**main**()
is also part of the TCB.
The threat model assumes that attackers can exploit existing vulnerabilities in
application (non-TCB) code to achieve arbitrary code execution.
However, the compiler toolchain used to build all application code is trusted
to produce ELF files that a) are well-formed and do not trigger parsing errors
and b) faithfully enact the compartmentalization policy, effectively excluding
supply-chain attacks on build systems.
Binary distribution mechanisms such as package managers are also trusted.

This work is an experimental work in progress and
*does not*
yet provide complete isolation between compartments.
Below are some known issues that will be addressed in future releases.

*	Although all function pointers defined in C/C++ are guaranteed to cause
	compartment transitions when necessary, 'wild' function pointers generated by
	assembly code are not.
	A compartment that calls a function pointer received from an untrusted
	compartment may therefore unexpectedly call such a 'wild' function pointer,
	breaking compartmentalization.

*	Any compartment is currently able to access any other compartment's thread
	local variables.

*	dlopen(3)
	can be used to access privileged data in
	rtld(1).

Additionally, some system APIs are known to potentially break
compartmentalization but are nonetheless functionally supported.

*	longjmp(3)
	and its variants can jump across compartment boundaries and destroy call frames
	along with any associated state that belong to other compartments, violating
	control-flow expectations for those bypassed compartments.

*	C++ exceptions can be thrown across compartment boundaries, during which the C++
	runtime may unexpectedly destroy state belonging to other compartments and
	violate their control-flow expectations.

*	Signal handlers can receive the machine context of the interrupted code, which
	may belong to another compartment.
	They can therefore bypass compartmentalization by inspecting or even modifying
	the machine context.

Furthermore, many system APIs, despite not breaking compartmentalization itself,
grant excessive privileges to the caller.
To ensure safety, a compartment should be denied access to most such APIs, and
all remaining uses should be audited.
Some examples of such APIs are:

*	open(2)
	can open arbitrary files in the file system.

*	ptrace(2)
	can modify the state of this or other processes.

*	dlopen(3)
	and related functions can load libraries that have more privileges
	than the calling compartment.

*	dl\_iterate\_phdr(3)
	can access the program headers of all loaded libraries.

*	elf\_aux\_info(3)
	can return highly privileged pointers.

*	unwinding-related APIs can cross compartment boundaries.

# AUTHORS

Dapeng Gao &lt;[dapeng.gao@cl.cam.ac.uk](mailto:dapeng.gao@cl.cam.ac.uk)&gt;

macOS 26.6 - May 11, 2026

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
