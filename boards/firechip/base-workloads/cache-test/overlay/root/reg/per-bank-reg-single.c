#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#define N_DOMAINS 4
#define N_CLIENTS 1
#include "per-bank-map.h"

// Can be used to configure regulation of a single core config, per-bank regualtion design
// Works for both 2 and 4 bank designs

int main(int argc, char* argv[]) {
    unsigned long register_size = sizeof(long unsigned int); // Size of each register (64-bit)
    unsigned long page_size = 4096;

    unsigned int window = strtoul(argv[1], NULL, 0);
    unsigned int maxReads = strtoul(argv[2], NULL, 0);
    unsigned int maxWrites = strtoul(argv[3], NULL, 0);

    int fd;
    unsigned long offset = BASE % page_size;
    unsigned long aligned_base = BASE - offset;
    unsigned long total_size = (NUM_REGS * register_size) + offset;
    void* mapped_base;
    volatile long unsigned int* mapped_addr;

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

    mapped_addr[GLOBAL_EN] = 0;
    mapped_addr[PERIOD_LEN] = window;
    mapped_addr[MAX_READ(0)] = maxReads; // Set domain 0 max reads
    mapped_addr[MAX_PUT(0)] = maxWrites; // Set domain 0 max puts -- ignore this if you don't have mempress in your system
    mapped_addr[CLIENT_EN(0)] = 0xffffffffffffffff; // being lazy and setting entire enable range to 1's
    mapped_addr[CLIENT_EN(1)] = 0xffffffffffffffff;
    mapped_addr[CLIENT_EN(2)] = 0xffffffffffffffff;
    mapped_addr[CLIENT_DOMAIN(0)] = 0; // Set client 0 to be in domain 0

    mapped_addr[GLOBAL_EN] = 1;

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
