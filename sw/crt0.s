.global _start
.section .text

_start:

    li sp, 2032

    jal ra, main

_infinite_loop:
    j _infinite_loop

