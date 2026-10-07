/**
 *
 * Copyright (C) 2012  Heechul Yun <heechul@illinois.edu>
 *               2012  Zheng <zpwu@uwaterloo.ca>
 *
 * This file is distributed under the University of Illinois Open Source
 * License. See LICENSE.TXT for details.
 *
 */

/* clang -S -mllvm --x86-asm-syntax=intel ./bandwidth.c */

/**************************************************************************
 * Conditional Compilation Options
 **************************************************************************/

/**************************************************************************
 * Included Files
 **************************************************************************/
#include <vector>

#include <cassert>
#include <dirent.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/resource.h>

/**************************************************************************
 * Public Definitions
 **************************************************************************/
#define CACHE_LINE_SIZE 64	   /* cache Line size is 64 byte */
#ifdef __arm__
#  define DEFAULT_ALLOC_SIZE_KB 4096
#else
#  define DEFAULT_ALLOC_SIZE_KB 16384
#endif

/**************************************************************************
 * Public Types
 **************************************************************************/
enum access_type { READ, WRITE };
enum corun_type { VICTIM, ATTACKER, SOLO };

/**************************************************************************
 * Global Variables
 **************************************************************************/
int g_mem_size = DEFAULT_ALLOC_SIZE_KB * 1024;	   /* memory size */
int g_small_mem_size = g_mem_size / 2;	   /* memory size */
int g_num_phases = 1;
int *g_mem_ptr = 0;		   /* pointer to allocated memory region */
int *g_itr_time = NULL;
int g_run_phases = 0;
uint64_t *g_itr_read = NULL;

corun_type g_corun = SOLO;
std::vector<pid_t> g_attacker_pids;

volatile uint64_t g_nread = 0;	           /* number of bytes read */
volatile unsigned int g_start;		   /* starting time */
volatile unsigned int g_end;		   /* starting time */
int cpuid = 0;
int g_stride = CACHE_LINE_SIZE;

/**************************************************************************
 * Public Functions
 **************************************************************************/
void victim_setup() {
	DIR* d = opendir("/tmp");
	struct dirent* entry;

	while ((entry = readdir(d)) != NULL) {
		if (strncmp(entry->d_name, "attacker_", 9) == 0) {
			char path[256];
			snprintf(path, sizeof(path), "/tmp/%s", entry->d_name);

			FILE* f = fopen(path, "r");

			pid_t process_id;
			fscanf(f, "%d", &process_id);
			g_attacker_pids.push_back(process_id);
			fclose(f);
			remove(path);
		}
	}
	closedir(d);
}

void attacker_setup() {
	char filename[128];
	pid_t process_id = getpid();

	sprintf(filename, "/tmp/attacker_%d.pid", process_id);
	FILE* f = fopen(filename, "w");
	fprintf(f, "%d\n", process_id);
	fclose(f);
}

void corun_setup() {
	if (g_corun == VICTIM) {
		victim_setup();
	} else if (g_corun == ATTACKER) {
		attacker_setup();
	}
}

unsigned int get_usecs()
{
	struct timeval         time;
	gettimeofday(&time, NULL);
	return (time.tv_sec * 1000000 +	time.tv_usec);
}

void quit(int param)
{
  for (int i = 0; i < g_run_phases; i++)
  {
    float dur_in_sec = (float)g_itr_time[i] / 1000000;
    int nread = i % 2 == 0 ? g_small_mem_size : g_mem_size;
    float bw = (float)(g_itr_read[i] / (g_stride / CACHE_LINE_SIZE)) / dur_in_sec / 1024 / 1024;
    if (nread == g_small_mem_size)
    {
      printf("small phase bytes read = %lld\n", (long long)g_itr_read[i]);
    } else {
      printf("large phase bytes read = %lld\n", (long long)g_itr_read[i]);
    }
    printf("CPU%d: B/W = %.2f MB/s | ",cpuid, bw);
    printf("CPU%d: average = %.2f ns\n\n", cpuid, ((float)g_itr_time[i]*1000)/(g_itr_read[i]/CACHE_LINE_SIZE));
  }

	if (g_corun == VICTIM) {
		for (pid_t pid : g_attacker_pids) {
			kill(pid, SIGINT);
		}
	}

	exit(0);
}

int64_t bench_read(int size, int j)
{
	int i;	
	int64_t sum = 0;
	for ( i = 0; i < size/4; i+=(g_stride/4) ) {
		sum += g_mem_ptr[i];
	}
	g_itr_read[j] += size;
	return sum;
}

int bench_write(int size, int j)
{
	register int i;	
	for ( i = 0; i < size/4; i+=(g_stride/4) ) {
		g_mem_ptr[i] = i;
	}
	g_itr_read[j] += size;
	return 1;
}

int64_t touch_set(int size, int acc_type, int j)
{
  int64_t temp = 0;
  switch (acc_type) {
    case READ:
      temp = bench_read(size, j);
      g_itr_read[j] -= size;
      return temp;
    case WRITE:
      temp = bench_write(size, j);
      g_itr_read[j] -= size;
      return temp;
  }

  printf("error in set warming\n");
  return 0;
}

void usage(int argc, char *argv[])
{
	printf("Usage: $ %s [<option>]*\n\n", argv[0]);
	printf("-m: memory size in KB. deafult=8192\n");
  printf("-z: small memory size in KB. default=size/2\n");
  printf("-y: number of times to run each phase. default=1\n");
	printf("-a: access type - read, write. default=read\n");
	printf("-n: addressing pattern - Seq, Row, Bank. default=Seq\n");
	printf("-t: time to run in sec. 0 means indefinite. default=5. split over phases \n");
	printf("-c: CPU to run.\n");
	printf("-i: iterations per-phase. default=0\n");
	printf("-p: priority\n");
	printf("-l: log label. use together with -f\n");
	printf("-f: log file name\n");
	printf("-h: help\n");
	printf("\nExamples: \n$ bandwidth -m 8192 -a read -t 1 -c 2\n  <- 8MB read for 1 second on CPU 2\n");
	exit(1);
}

int main(int argc, char *argv[])
{
	int64_t sum = 0;
	unsigned finish = 5;
	int prio = 0;        
	int num_processors;
	int acc_type = READ;
	int opt;
	cpu_set_t cmask;
	int iterations = 100;
	int use_hugepage = 0;	
	int i;
	size_t j;
	struct sched_param param;

	/*
	 * get command line options 
	 */
	while ((opt = getopt(argc, argv, "y:z:s:m:a:n:t:c:i:p:r:f:l:xh")) != -1) {
		switch (opt) {
		case 'm': /* set memory size */
			g_mem_size = 1024 * strtol(optarg, NULL, 0);
			break;
    case 'z': /* set small memory size */
      g_small_mem_size = 1024 * strtol(optarg, NULL, 0);
      break;
    case 'y':
      g_num_phases = strtol(optarg, NULL, 0);
      break;
		case 'a': /* set access type */
			if (!strcmp(optarg, "read"))
				acc_type = READ;
			else if (!strcmp(optarg, "write"))
				acc_type = WRITE;
			else
				exit(1);
			break;
			
		case 't': /* set time in secs to run */
			finish = strtol(optarg, NULL, 0);
			break;
                case 'x':
			use_hugepage = (use_hugepage) ? 0: 1;
			break;
		case 'c': /* set CPU affinity */
			cpuid = strtol(optarg, NULL, 0);
			num_processors = sysconf(_SC_NPROCESSORS_CONF);
			CPU_ZERO(&cmask);
			CPU_SET(cpuid % num_processors, &cmask);
			if (sched_setaffinity(0, num_processors, &cmask) < 0)
				perror("error");
			else
				fprintf(stderr, "assigned to cpu %d\n", cpuid);
			break;

		case 'r':
			prio = strtol(optarg, NULL, 0);
			param.sched_priority = prio; /* 1(low)- 99(high) for SCHED_FIFO or SCHED_RR
						        0 for SCHED_OTHER or SCHED_BATCH */
			if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
				perror("sched_setscheduler failed");
			}
			break;
		case 'p': /* set priority */
			prio = strtol(optarg, NULL, 0);
			if (setpriority(PRIO_PROCESS, 0, prio) < 0)
				perror("error");
			else
				fprintf(stderr, "assigned priority %d\n", prio);
			break;
		case 'i': /* iterations */
			iterations = strtol(optarg, NULL, 0);
			break;
		case 's':
			g_stride = strtol(optarg, NULL, 0);
			break;
		case 'f':
			if (!strcmp(optarg, "victim")) {
				g_corun = VICTIM;
			} else if (!strcmp(optarg, "attacker")) {
				g_corun = ATTACKER;
			} else {
				exit(1);
			}
			break;
		case 'h': 
			usage(argc, argv);
			break;
		}
	}

  assert(g_mem_size >= g_small_mem_size);

	/*
	 * allocate contiguous region of memory 
	 */ 
	if (use_hugepage) {
		g_mem_ptr = (int *)mmap(0, 
				       g_mem_size,
				       PROT_READ | PROT_WRITE, 
				       MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, 
				       -1, 0);
		if ((void *)g_mem_ptr == MAP_FAILED) {
			perror("alloc failed");
			exit(1);
		}
	} else {
		g_mem_ptr = (int *)malloc(g_mem_size);
		if (g_mem_ptr == NULL) {
			perror("alloc failed");
			exit(1);
		}
		printf("Using malloc(), not very accurate\n");
	}
	
	memset((char *)g_mem_ptr, 1, g_mem_size);

	for (j = 0; j < g_mem_size / sizeof(int); j++)
		g_mem_ptr[j] = j;

	/* print experiment info before starting */
	printf("memsize=%d KB, smallsize=%d KB, type=%s, cpuid=%d, stride=%d, num_phase_runs=%d\n",
			g_mem_size/1024,
      g_small_mem_size/1024,
			((acc_type==READ) ?"read": "write"),
			cpuid,
			g_stride,
      g_num_phases);
	printf("stop at %d\n", finish);

	/* set signals to terminate once time has been reached */
	signal(SIGINT, &quit);
	if (finish > 0) {
		//signal(SIGALRM, &quit);
		//alarm(finish);
	}

	if (g_corun != SOLO) {
		corun_setup();
	}

  g_num_phases *= 2;
  g_itr_time = (int*)malloc(g_num_phases * sizeof(int));
  g_itr_read = (uint64_t*)malloc(g_num_phases * sizeof(uint64_t));
  memset(g_itr_read, 0, g_num_phases * sizeof(uint64_t));

	/*
	 * actual memory access
	 */
  for (int j = 0;; j++) {
    int size = j % 2 == 0 ? g_small_mem_size : g_mem_size;
    sum += touch_set(size, acc_type, j);

	  g_start = get_usecs();
	  for (i=0;; i++) {
		  switch (acc_type) {
		  case READ:
			  sum += bench_read(size, j);
			  break;
		  case WRITE:
			  sum += bench_write(size, j);
			  break;
		  }

		  if (i+1 >= iterations)
		  	break;
	  }
    g_end = get_usecs();
    g_itr_time[j] = g_end - g_start;
    g_run_phases += 1;
    if (g_num_phases > 0 && j + 1 >= g_num_phases)
      break;
  }
	printf("total sum = %ld\n", (long)sum);
	quit(0);
	return 0;
}

