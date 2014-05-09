export PATH			:=	$(PATH):$(DEVKITSNES)/cc65/
export EMULATORS	:=	$(DEVKITPRO)/emulators/snes

snes9x		:= $(EMULATORS)/snes9x/snes9x-x64
higan1		:= $(EMULATORS)/higan/higan-performance
higan2		:= $(EMULATORS)/higan/higan-balanced
higan3		:= $(EMULATORS)/higan/higan-accuracy

ASFLAGS		:= 
LDFLAGS		:= -C lorom.cfg

BUILD		:= build
TARGET		:= $(shell basename $(CURDIR))
OUTPUT		:= $(CURDIR)/$(TARGET).sfc

SFILES		:= main.s
OFILES		:= $(SFILES:.s=.o)

#----------------------------------------------------------
%.o: %.s
	ca65 -o $@ $(ASFLAGS) -g -l $<.map $<

%.sfc:
	ld65 -o $@ $(LDFLAGS) -Ln $(TARGET).sym -vm -m $<.map $(OFILES)
#----------------------------------------------------------
.PHONY: all clean run run2

all: $(OUTPUT)

clean:
	find . -regex '.*\.[so]\.map' | xargs -d"\n" rm
	rm -r $(OUTPUT) $(OFILES)

run: all
	$(snes9x) $(OUTPUT)

run2: all
	$(higan3) $(OUTPUT)

$(OUTPUT): $(OFILES)


