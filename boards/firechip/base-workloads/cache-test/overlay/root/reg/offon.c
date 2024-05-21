#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    int fd;
    unsigned long base_address = 0x20000098; // Starting address of the first register
    unsigned long num_registers = 1; // Number of registers to read
    unsigned long register_size = sizeof(unsigned int)*2; // Size of each register (64-bit)
    unsigned long page_size = 4096;
    unsigned long offset = base_address % page_size;
    unsigned long aligned_base = base_address - offset;
    unsigned long total_size = (num_registers * register_size) + offset;
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

    mapped_addr[0] = 0;
    mapped_addr[0] = 1;

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
