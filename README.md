
A SuperFX assembler for ca65, just include sfx65.inc in the gsu folder and you're good to go (requires at least ca65 and ld65, get here http://oliverschmidt.github.io/cc65/).

Use the autonop "directive" to have the assembler automatically insert a nop opcode after jal and ret pseudo-ops.

To enable inline GSU assembly, define GSU_INLINE (can be any value, as long as the symbol is defined) before including sfx65.inc.
This will allow you to assemble GSU code in a 65816 assembly file, however all GSU opcodes (except move/moves/moveb/movew) are prefixed with an m to avoid collisions.

	mwith R15
	mto R1
	mplot
	mmult #5
	you get the idea

By ARM9, dec 8th 2013
