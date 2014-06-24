export PATH			:=	$(PATH):$(DEVKITSNES)/cc65/
export EMULATORS	:=	$(DEVKITPRO)/emulators/snes

AS	:= ca65
LD	:= ld65

higan-p		:= $(EMULATORS)/higan/higan-performance
higan-b		:= $(EMULATORS)/higan/higan-balanced
higan-a		:= $(EMULATORS)/higan/higan-accuracy

ifeq ($(OS),Windows_NT)
snes9x		:= $(EMULATORS)/snes9x/snes9x-x64
else
snes9x		:= $(EMULATORS)/snes9x/snes9x-gtk
endif

ASFLAGS		:= 
LDFLAGS		:= -C lorom.cfg

BUILD		:= build
TARGET		:= $(shell basename $(CURDIR))
OUTPUT		:= $(CURDIR)/$(TARGET).sfc

SFILES		:= main.s
OFILES		:= $(SFILES:.s=.o)

#----------------------------------------------------------
%.o: %.s
	$(AS) -o $@ $(ASFLAGS) -g -l $<.map $<
#----------------------------------------------------------
.PHONY: clean run run2

all: $(OUTPUT)


clean:
	find . -regex '.*\.[so]\.map' | xargs -d"\n" rm
	rm -r $(OUTPUT) $(OFILES)

run: all
	$(snes9x) $(OUTPUT)

run2: all
	$(higan-a) $(OUTPUT)

$(OUTPUT): $(OFILES)
	$(LD) -o $@ $(LDFLAGS) -Ln $(TARGET).sym -vm -m $<.map $(OFILES)

