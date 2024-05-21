
RISCV_PFX=riscv64-unknown-linux-gnu-gcc
RISCV_CC=$(RISCV_PFX)

BINARY_OPT=-static 

BINS=counters regulate reg-single offon

all: $(BINS)

counters: counters.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

regulate: regulate.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

reg-single: regulate-single.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

offon: offon.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

.PHONY: clean
clean:
	rm -f $(BINS)
