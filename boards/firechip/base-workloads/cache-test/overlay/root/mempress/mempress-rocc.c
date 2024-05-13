#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <malloc.h>
#include <unistd.h>
#include <bits/getopt_core.h>
#include <sys/mman.h>
#include <stdbool.h>

#include "rocc.h"
#include "compiler.h"
#include "encoding.h"
 
#define MAX_STREAMS 16
#define CL_BYTES 64
#define BUS_WIDTH_BYTES 16
#define KB 1024

#define BITS_PER_LONG 64
#define BITOP_WORD(nr)		((nr) / BITS_PER_LONG)

enum STREAM_TYPE {
    STRIDE_RD = 0,
    STRIDE_WR = 1,
    BURST_RD = 2,
    BURST_WR = 3,
    RAND_RD = 4,
    RAND_WR = 5
};

static __always_inline unsigned long __ffs(unsigned long word)
{
        int num = 0;

#if BITS_PER_LONG == 64
        if ((word & 0xffffffff) == 0) {
                num += 32;
                word >>= 32;
        }
#endif
        if ((word & 0xffff) == 0) {
                num += 16;
                word >>= 16;
        }
        if ((word & 0xff) == 0) {
                num += 8;
                word >>= 8;
        }
        if ((word & 0xf) == 0) {
                num += 4;
                word >>= 4;
        }
        if ((word & 0x3) == 0) {
                num += 2;
                word >>= 2;
        }
        if ((word & 0x1) == 0)
                num += 1;
        return num;
}

/*
 * Find the next set bit in a memory region.
 */
unsigned long find_next_bit(const unsigned long *addr, unsigned long size,
			    unsigned long offset)
{
	const unsigned long *p = addr + BITOP_WORD(offset);
	unsigned long result = offset & ~(BITS_PER_LONG-1);
	unsigned long tmp;

	if (offset >= size)
		return size;
	size -= result;
	offset %= BITS_PER_LONG;
	if (offset) {
		tmp = *(p++);
		tmp &= (~0UL << offset);
		if (size < BITS_PER_LONG)
			goto found_first;
		if (tmp)
			goto found_middle;
		size -= BITS_PER_LONG;
		result += BITS_PER_LONG;
	}
	while (size & ~(BITS_PER_LONG-1)) {
		if ((tmp = *(p++)))
			goto found_middle;
		result += BITS_PER_LONG;
		size -= BITS_PER_LONG;
	}
	if (!size)
		return result;
	tmp = *p;

found_first:
	tmp &= (~0UL >> (BITS_PER_LONG - size));
	if (tmp == 0UL)		/* Are any bits set? */
		return result + size;	/* Nope. */
found_middle:
	return result + __ffs(tmp);
}

#define find_first_bit(addr, size) find_next_bit((addr), (size), 0)

#define for_each_set_bit(bit, addr, size) \
	for ((bit) = find_first_bit((addr), (size));		\
	     (bit) < (size);					\
	     (bit) = find_next_bit((addr), (size), (bit) + 1))

int paddr_to_color(unsigned long mask, unsigned long paddr)
{
	int color = 0;
	int idx = 0;
	unsigned long c = 0;
	for_each_set_bit(c, &mask, BITS_PER_LONG) {
		if ((paddr >> (c)) & 0x1)
			color |= (1<<idx);
		idx++;
	}
	return color;
}

void printConfig(int mem_size, int req_multplier, int stride, int streams, enum STREAM_TYPE stream_type, int mask, int colors) {
  printf("Stream count: %d | stream type: %d | stride size: %d\n", streams, stream_type, stride);
  printf("Memory size(KB): %d | request count %d\n", mem_size, req_multplier);
  printf("Bank mask: %x | color count: %d\n", mask, colors);
}

int main(int argc, char* argv[]) {
  enum STREAM_TYPE stream_type  = STRIDE_RD;
  int mem_size = 128 * KB;     //allocated mem size in KB
  int max_reqs = 15000;        //number of iterations
  int stride_bytes = CL_BYTES; //streams stride size
  int stream_cnt = 16;         //number of streams (max is 16)
  int bank_mask = 0x40;
  int colors[4] = {0};
  int color_cnt = 0;
  bool using_huge_page = false;

  unsigned long long cycle_cnt = 0;
  unsigned long long req_sent = 0;
  
  rdtime();

  int opt;
  while ( ( opt = getopt(argc, argv, "a:b:e:m:s:i:w:hx") ) != -1 ) {
    switch ( opt )
    {
    case 'a':
      if ( !strcmp(optarg, "sw") ) {
        stream_type  = STRIDE_WR;
      } else if ( !strcmp(optarg, "rr") ) {
        stream_type = RAND_RD;
      } else if ( !strcmp(optarg, "rw") ) {
        stream_type = RAND_WR;
      } else if ( !strcmp(optarg, "sr") ) {
        stream_type = STRIDE_RD;
      }
      break;
    case 'b':
      bank_mask = strtol(optarg, NULL, 0);
      break;
    case 'e':
      colors[0] = strtol(optarg, NULL, 0);
      color_cnt = 1;
      break;
    case 'm':
      mem_size = KB * strtol(optarg, NULL, 0);
      break;
    case 's':
      stride_bytes = strtol(optarg, NULL, 0);
      break;
    case 'i':
      max_reqs = strtol(optarg, NULL, 0);
      break;
    case 'w':
      stream_cnt = strtol(optarg, NULL, 0);
      assert(stream_cnt <= MAX_STREAMS);
      break;
    case 'x':
      using_huge_page = true;
      break;
    default:
      printf("unkown arg %c\n", opt);
      break;
    }

  }

  printConfig(mem_size, max_reqs, stride_bytes, stream_cnt, stream_type, bank_mask, color_cnt);

  printf("main() started\n");

  assert(stream_cnt <= MAX_STREAMS);

  printf("Allocating memory\n");
  char* input = NULL;

  int page_stride = 4 * KB;
  if ( using_huge_page ) {
    printf("using huge page\n");
    input = mmap(0, 
				       mem_size,
				       PROT_READ | PROT_WRITE, 
				       MAP_PRIVATE | 0x20 | 0x40000, 
				       -1, 0);
    page_stride = 2000 * KB;
  } else {
    printf("using malloc\n");
    input = memalign(sizeof(char), (size_t)mem_size);
  }

  memset(input, 0, sizeof(input));

  printf("Prevents page faults by touching them\n");
  for ( int i = 0; i < mem_size; i += page_stride ) {
      input[i] = '3'; // 0011_0011
  }

  // Ensure all pages are resident to avoid accelerator page faults
  if ( mlockall(MCL_CURRENT | MCL_FUTURE) ) {
    perror("mlockall");
    return 1;
  }

  int index = 0;
  if ( color_cnt == 1 ) {
    for ( int i = 0; i < mem_size; i+=CL_BYTES ) {
      unsigned long vaddr = (unsigned long)&input[i];
      if ( paddr_to_color(bank_mask, vaddr) == colors[0] ) {
        printf("matched color %d\n", colors[0]);
        index = i;
        break;
      }
    }
  }

  printf("index is %d\n", index);

  int idx_offset[MAX_STREAMS];
  for ( int i = 0; i < stream_cnt; i++ ) {
    if ( color_cnt == 1 ) {
      idx_offset[i] = ( index + ( stride_bytes * i ) ) % mem_size;
    } else {
      idx_offset[i] = ( stride_bytes * i ) % mem_size;
    }
  }

  printf("Begin accesses\n");

  // insert fence instruction
  asm volatile ("fence");

  // number of streams && max request per stream
  uint64_t stream_cnt_n_addr_range = (mem_size << 5) | (stream_cnt);
  ROCC_INSTRUCTION_SS(2, stream_cnt_n_addr_range, max_reqs, 1);
  for (int i = 0; i < stream_cnt; i++) {
      uint64_t stride_n_type = (stride_bytes << 3) | ((int)stream_type);

      //set per stream stride, type, starting addr
      ROCC_INSTRUCTION_SS(2, stride_n_type, &input[idx_offset[i]], 2);
  }

  // get hw counter values
  ROCC_INSTRUCTION_D(2, cycle_cnt, 3);
  ROCC_INSTRUCTION_D(2, req_sent, 4);

  // remove fence instruction
  asm volatile ("fence" ::: "memory");

  assert(cycle_cnt != 0);
  unsigned long long bytes_sent = req_sent * BUS_WIDTH_BYTES; //we aren't moving cache lines
  unsigned long long nano_sec = cycle_cnt;
  unsigned long long bw_MBps = (bytes_sent * 1000) / nano_sec;

  printf("cycle_cnt value: %llu\n", cycle_cnt);
  printf("req_sent value: %llu\n", req_sent);

  printf("Achieved BW of the system: %llu MB/s\n", bw_MBps);

  printf("Execution Finished!\n");
  return 0;
}
