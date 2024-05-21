#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
    unsigned long base_address = 0x20000000; // Starting address of the first register
    unsigned long num_registers = 81; // Number of registers to read
    unsigned long register_size = sizeof(unsigned int); // Size of each register (32-bit)
    unsigned long page_size = 4096;

    unsigned int window = strtoul(argv[1], NULL, 0);
    unsigned int maxReads = strtoul(argv[2], NULL, 0);
    unsigned int maxWrites = strtoul(argv[3], NULL, 0);

    int fd;
    unsigned long offset = base_address % page_size;
    unsigned long aligned_base = base_address - offset;
    unsigned long total_size = (num_registers * register_size) + offset;
    void* mapped_base;
    volatile unsigned int* mapped_addr;

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

    mapped_addr[0] = 0;
    mapped_addr[2] = window;
    mapped_addr[3] = maxReads;
    mapped_addr[7] = maxWrites;
    mapped_addr[15] = 0xfffffffe;
    mapped_addr[16] = 0xffffffff;
    mapped_addr[17] = 0xffffffff;

    for (int i = 19; i < num_registers; i++) {
        mapped_addr[i] = 0;
    }

    mapped_addr[0] = 1;

    // Unmap and close
    if (munmap(mapped_base, total_size) == -1) {
        perror("munmap");
    }
    close(fd);

    return 0;
}
