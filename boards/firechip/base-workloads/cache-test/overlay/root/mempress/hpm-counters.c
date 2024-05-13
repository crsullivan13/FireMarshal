#include <stdio.h>

#include "encoding.h"

#define read_csr_safe(reg) ({ register long __tmp asm("a0"); \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

int main() {
    write_csr(mcounteren, -1);                            
    write_csr(scounteren, -1);
    write_csr(mhpmevent3, 0x202);
    printf("cycles: %lu\n", rdcycle());
    printf("instr ret: %lu\n", rdinstret());
    printf("dcache miss: %lu\n", read_csr_safe(mhpmcounter3));
}
