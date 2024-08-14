#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#define N_DOMAINS 4
#define N_CLIENTS 51 // Looks wrong, but mempress edges are all separate clients
#include "mmio-map.h"

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
    mapped_addr[MAX_READ(0)] = maxReads;
    mapped_addr[MAX_PUT(0)] = maxWrites; // Puts are how Mempress writes, different from write-backs from cores
    mapped_addr[CLIENT_EN(0)] = 0xfffffffffffffffe; // Enable regulation on everything but BOOM core
    mapped_addr[CLIENT_EN(1)] = 0xffffffffffffffff;
    mapped_addr[CLIENT_EN(2)] = 0xffffffffffffffff;
    mapped_addr[CLIENT_DOMAIN(0)] = 1; // Place BOOM core in own domain

    for (int i = 1; i < N_CLIENTS; i++) {
        mapped_addr[CLIENT_DOMAIN(i)] = 0; // Place Rocket and Mempress edges into domain
    }

    mapped_addr[GLOBAL_EN] = 1;

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
