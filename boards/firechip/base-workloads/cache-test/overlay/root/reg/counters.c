#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#define N_DOMAINS 4
#define N_CLIENTS 1
#define N_BANKS 4
#include "per-bank-map.h"

#define N_COUNTERS 8

// For reading performance counters of a single core config
// Always reads 8 counters (4 read, 4 write), in a 2-bank config the last four will be zero

// Not all designs have these counters, only per-bank configs can have them
// Have to include in design through config param

int main() {
    unsigned long register_size = sizeof(long unsigned int); // Size of each register (64-bit)
    unsigned long page_size = 4096;

    int fd;
    unsigned long offset = BASE % page_size;
    unsigned long aligned_base = BASE - offset;
    unsigned long total_size = (NUM_REGS * register_size) + offset;
    void* mapped_base;
    volatile long unsigned int* mapped_addr;
    long unsigned int* vals = (long unsigned int*)malloc(sizeof(unsigned int)*N_COUNTERS);

    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    mapped_base = mmap(0, total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, aligned_base);
    if (mapped_base == (void *) -1) {
        perror("mmap");
        close(fd);
        return 1;
    }

    mapped_addr = (volatile long unsigned int *)(mapped_base + offset);

    // Read 8 counters
    // If we only have two banks, last four should be constant 0
    for (unsigned long i = 0; i < N_COUNTERS; i++) {
        long unsigned int index = 0;
        if ( i < 4 ) {
            index = READ_CNTR(0,i);
        } else {
            index = WRITE_CNTR(0,i);
        }

        vals[i] = mapped_addr[index];
        printf("Value at address 0x%lx: %lu\n", index * 8, vals[i]);
    }

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
