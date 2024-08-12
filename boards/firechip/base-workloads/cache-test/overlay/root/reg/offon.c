#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#define N_DOMAINS 4
#define N_CLIENTS 1
#include "per-bank-map.h"

// Lazy, but use this to turn perf counters off then back on to zero before running an experiment

int main() {
    unsigned long register_size = sizeof(long unsigned int); // Size of each register (64-bit)
    unsigned long page_size = 4096;

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

    mapped_addr = (long volatile unsigned int *)(mapped_base + offset);

    mapped_addr[PERF_EN] = 0;
    mapped_addr[PERF_EN] = 1;

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
