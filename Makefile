export PATH			:=	$(PATH):$(DEVKITSNES)/cc65/
export EMULATORS	:=	$(DEVKITPRO)/emulators/snes

AS	:= ca65
LD	:= ld65

higan-p		:= $(EMULATORS)/../higan/higan-performance
higan-b		:= $(EMULATORS)/../higan/higan-balanced
higan-a		:= $(EMULATORS)/../higan/higan-accuracy

ifeq ($(OS),Windows_NT)
snes9x		:= $(EMULATORS)/snes9x/snes9x-x64
else
snes9x		:= $(EMULATORS)/snes9x/snes9x-gtk
endif

BUILD		:= build
SOURCES		:= . gsu
TARGET		:= $(shell basename $(CURDIR))
OUTPUT		:= $(CURDIR)/$(TARGET).sfc

ASFLAGS		:= -g -l main.asm.map 
LDFLAGS		:= -C lorom.cfg -Ln $(TARGET).sym -vm -m main.o.map 

SFILES		:= $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.asm)))

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))

#----------------------------------------------------------
.PHONY: clean run run2

all: $(OUTPUT)
	

clean:
	find . -regex '.*\.\(asm\|o\)\.map' | xargs -d"\n" rm
	rm -r $(OUTPUT) $(TARGET).sym main.o

run: all
	$(snes9x) $(OUTPUT)

run2: all
	$(higan-a) $(OUTPUT)

$(OUTPUT): $(SFILES)
	$(AS) -o main.o $(ASFLAGS) main.asm
	$(LD) -o $@ $(LDFLAGS) main.o

