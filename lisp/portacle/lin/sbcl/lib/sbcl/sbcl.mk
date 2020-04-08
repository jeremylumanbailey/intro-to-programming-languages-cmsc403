CC=cc
LD=ld
CFLAGS= -fno-omit-frame-pointer -D_GNU_SOURCE -g -Wall -Wundef -Wsign-compare -Wpointer-arith -O3 -Wunused-parameter -fno-omit-frame-pointer -momit-leaf-frame-pointer
ASFLAGS= -fno-omit-frame-pointer -D_GNU_SOURCE -g -Wall -Wundef -Wsign-compare -Wpointer-arith -O3 -Wunused-parameter -fno-omit-frame-pointer -momit-leaf-frame-pointer
LINKFLAGS=-g -Wl,--export-dynamic
LDFLAGS=
__LDFLAGS__=
LIBS=-ldl -lpthread -lz -lm
