// Contains definitions to help with configuring the MMIO registers of per-bank regulation unit
// Reference the BwRegulator Chisel code to see where these values come from

#define BASE 0x20000000 // Reg-map base address
#define MAX  0x20000800 // Reg-map max address
#define NUM_REGS ( ( MAX - BASE ) / 8 ) // Assumes 8 byte fields, bit weird

#ifndef N_BANKS
#define N_BANKS 2
#endif

#define GLOBAL_EN 0
#define SETTINGS 1
#define PERIOD_LEN 2

#define MAX_READ(i) ( ( 24 + i * 8 ) / 8 )
#define MAX_PUT(i)  ( ( 24 + 8 * N_DOMAINS + i * 8 ) / 8 )
#define MAX_WB(i)   ( ( 24 + 2 * 8 * N_DOMAINS + i * 8 ) / 8 )

// Assuming you are reading 8 bytes at a time
#define CLIENT_EN(i) ( ( 24 + 3 * 8 * N_DOMAINS + 8 * i ) / 8 )

#define CLIENT_DOMAIN(i) ( ( 48 + 3 * 8 * N_DOMAINS + i * 8 ) / 8 )

#define PERF_EN ( 48 + 3 * 8 * N_DOMAINS + N_CLIENTS * 8 ) / 8

// Remove this?
#define PERF_PERIOD ( 56 + 3 * 8 * N_DOMAINS + N_CLIENTS * 8 ) / 8

// i -> client, j -> bank
#define READ_CNTR(i, j) ( ( 8 * ( 8 + 3 * N_DOMAINS + N_CLIENTS + i * N_BANKS + j ) ) / 8 )
#define WRITE_CNTR(i, j) ( ( 8 * ( 8 + 3 * N_DOMAINS + N_CLIENTS + N_CLIENTS * N_BANKS + i * N_BANKS + j ) ) / 8 )


