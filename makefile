TARGET = asmir
ASM_SOURCE = $(TARGET).asm
ASM_OBJECT = $(TARGET).o

all: $(TARGET)

$(ASM_OBJECT): $(ASM_SOURCE)
	nasm -f elf64 $< -o $@

$(TARGET): $(ASM_OBJECT)
	ld $< -o $@
	chmod +x $@

run: $(TARGET)
	./$(TARGET); echo "Exit code: $$?"


clean:
	rm -f $(ASM_OBJECT) $(TARGET)

.PHONY: all run clean			