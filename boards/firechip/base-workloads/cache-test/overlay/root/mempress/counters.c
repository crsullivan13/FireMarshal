#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    int fd;
    unsigned long base_address = 0x20000054; // Starting address of the first register
    unsigned long num_registers = 8; // Number of registers to read
    unsigned long register_size = sizeof(unsigned int); // Size of each register (32-bit)
    unsigned long page_size = 4096;
    unsigned long offset = base_address % page_size;
    unsigned long aligned_base = base_address - offset;
    unsigned long total_size = (num_registers * register_size) + offset;
    void* mapped_base;
    volatile unsigned int* mapped_addr;
    unsigned int* vals = (unsigned int*)malloc(sizeof(unsigned int)*num_registers);

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

    mapped_addr = (volatile unsigned int *)(mapped_base + offset);

    for (unsigned long i = 0; i < num_registers; i++) {
        vals[i] = mapped_addr[i];
        printf("Value at address 0x%lx: %d\n", base_address + (i * register_size), vals[i]);
    }

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
