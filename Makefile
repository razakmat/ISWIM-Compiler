# Usage examples:
#
#   make
#     Builds all of the ISWIM programs listed in the `all` target.
#
#   make five-const.iswim
#     Builds the executable `five-const.iswim` from the source program
#     `five-const.iswim.rktd`. The intermediate C file is deleted
#     after the executable is built.
#
#   make five-const.iswim.c
#     Builds the C file `five-const.iswim.c` by running the compiler
#     on the source program `five-const.iswim.rktd`. Useful for
#     inspecting and debugging the compiler's output.

CFLAGS=-g
LDFLAGS=-lgc
INC_FILES=program-prefix.inc main-prefix.inc

# Add more ISWIM programs here to the `all` target when the compiler
# support their features.
PROGRAMS=five-const.iswim

all: $(PROGRAMS)

runtime.o: runtime.c runtime.h
	$(CC) $(CFLAGS) -c -o runtime.o runtime.c

%.iswim: %.iswim.c runtime.h runtime.o $(INC_FILES)
	$(CC) $(CFLAGS) -o $@ $< runtime.o $(LDFLAGS)

%.iswim.c: %.iswim.rktd compiler.rkt
	racket compiler.rkt < $< > $@

clean:
	rm *.o *.iswim.c *.iswim
