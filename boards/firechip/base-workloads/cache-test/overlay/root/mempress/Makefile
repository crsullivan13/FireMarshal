
RISCV_PFX=riscv64-unknown-linux-gnu-gcc
RISCV_CC=$(RISCV_PFX)

BINARY_OPT=-static 
#-specs=htif_nano.specs

TARGET=mempress-rocc
TARGET_RISCV=$(TARGET).riscv
JUNK += $(TARGET_RISCV)

all: $(TARGET_RISCV)

$(TARGET_RISCV): mempress-rocc.c
	$(RISCV_CC) $(BINARY_OPT) -o $@ $^

.PHONY: clean
clean:
	rm -f $(JUNK)
