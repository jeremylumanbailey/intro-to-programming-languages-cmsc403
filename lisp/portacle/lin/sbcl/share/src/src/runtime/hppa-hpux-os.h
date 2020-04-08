#ifndef _HPPA_HPUX_OS_H
#define _HPPA_HPUX_OS_H

typedef struct ucontext_t os_context_t;
typedef unsigned long os_context_register_t;

#include "arch-os-generic.inc"

unsigned long os_context_fp_control(os_context_t *context);
void os_restore_fp_control(os_context_t *context);

#define REGISTER_ACCESS(context,offset) ((os_context_register_t *) ((unsigned int)(&((ucontext_t *) context)->uc_mcontext.ss_wide.ss_64)) + (offset * 2) + 1)

#endif /* _HPPA_HPUX_OS_H */
