/*
 * This is a machine-generated file. Please do not edit it by hand.
 * (As of sbcl-0.8.14, it came from WRITE-CONFIG-H in genesis.lisp.)
 *
 * This file contains low-level information about the
 * internals of a particular version and configuration
 * of SBCL. It is used by the C compiler to create a runtime
 * support environment, an executable program in the host
 * operating system's native format, which can then be used to
 * load and run 'core' files, which are basically programs
 * in SBCL's own format.
 */
#ifndef SBCL_GENESIS_SIMPLE_FUN
#define SBCL_GENESIS_SIMPLE_FUN
#ifndef __ASSEMBLER__

struct simple_fun {
    lispobj header;
    lispobj self;
    unsigned char insts[1];
};

#else /* __ASSEMBLER__ */

/* These offsets are SLOT-OFFSET * N-WORD-BYTES - LOWTAG
 * so they work directly on tagged addresses. */

#define SIMPLE_FUN_SELF_OFFSET -3
#define SIMPLE_FUN_INSTS_OFFSET 5
#define SIMPLE_FUN_SIZE 2

#endif /* __ASSEMBLER__ */

#endif
