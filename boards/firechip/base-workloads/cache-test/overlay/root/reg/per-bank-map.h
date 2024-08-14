// Contains definitions to help with configuring the MMIO registers of per-bank regulation unit
// Reference the BwRegulator Chisel code to see where these values come from

#include "mmio-map.h"

#ifndef N_BANKS
#define N_BANKS 2
#endif

// i -> client, j -> bank
#define READ_CNTR(i, j) ( ( 8 * ( 8 + 3 * N_DOMAINS + N_CLIENTS + i * N_BANKS + j ) ) / 8 )
#define WRITE_CNTR(i, j) ( ( 8 * ( 8 + 3 * N_DOMAINS + N_CLIENTS + N_CLIENTS * N_BANKS + i * N_BANKS + j ) ) / 8 )


