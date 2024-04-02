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

enum STREAM_TYPE {
    STRIDE_RD = 0,
    STRIDE_WR = 1,
    BURST_RD = 2,
    BURST_WR = 3,
    RAND_RD = 4,
    RAND_WR = 5
};

void printConfig(int mem_size, int req_multplier, int stride, int streams, enum STREAM_TYPE stream_type) {
  printf("Stream count: %d | stream type: %d | stride size: %d\n", streams, stream_type, stride);
  printf("Memory size(KB): %d | request multiplier %d\n", mem_size, req_multplier);
}

int main(int argc, char* argv[]) {
  enum STREAM_TYPE stream_type  = STRIDE_RD;
  int mem_size = 128 * KB;     //allocated mem size in KB
  int max_req_multplier = 1;   //what to mult max requests by, TODO change max requests
  int stride_bytes = CL_BYTES; //streams stride size
  int stream_cnt = 16;         //number of streams (max is 16)
  bool using_huge_page = false;

  int i;
  unsigned long long cycle_cnt = 0;
  unsigned long long req_sent = 0;

  int opt;
  while ( ( opt = getopt(argc, argv, "a:m:s:i:w:hx") ) != -1 ) {
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
    case 'm':
      mem_size = KB * strtol(optarg, NULL, 0);
      break;
    case 's':
      stride_bytes = strtol(optarg, NULL, 0);
      break;
    case 'i':
      max_req_multplier = strtol(optarg, NULL, 0);
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

  printConfig(mem_size, max_req_multplier, stride_bytes, stream_cnt, stream_type);

  printf("main() started\n");

  int max_reqs = mem_size / (stream_cnt * 2 * CL_BYTES);
  assert(stream_cnt <= MAX_STREAMS);

  int idx_offset[MAX_STREAMS];
  for (i = 0; i < stream_cnt; i++) {
      idx_offset[i] = 128 * i;
  }
  int max_idx = mem_size;

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

  //TODO: If using huge pages, what's the page size?
  printf("Prevents page faults by touching them\n");
  for (i = 0; i < max_idx; i += page_stride) {
      input[i] = '3'; // 0011_0011
  }

  // Ensure all pages are resident to avoid accelerator page faults
  if (mlockall(MCL_CURRENT | MCL_FUTURE)) {
    perror("mlockall");
    return 1;
  }

  printf("Begin accesses\n");

  // insert fence instruction
  asm volatile ("fence");

  // number of streams && max request per stream
  uint64_t stream_cnt_n_addr_range = (mem_size << 5) | (stream_cnt);
  ROCC_INSTRUCTION_SS(2, stream_cnt_n_addr_range, max_reqs * max_req_multplier, 1);
  for (i = 0; i < stream_cnt; i++) {
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
