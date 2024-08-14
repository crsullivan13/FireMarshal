
RISCV_PFX=riscv64-unknown-linux-gnu-gcc
RISCV_CC=$(RISCV_PFX)

BINARY_OPT=-static -Wall

BINS=counters regulate-mempress regulate-single offon

all: $(BINS)

counters: counters.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

regulate-mempress: regulate-mempress.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

regulate-single: regulate-single.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

offon: offon.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

.PHONY: clean
clean:
	rm -f $(BINS)
