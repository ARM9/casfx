
## A SuperFX assembler for ca65 ##
Install the toolchain from https://cc65.github.io/ and include [casfx.inc](https://raw.githubusercontent.com/ARM9/casfx/master/gsu/casfx.inc) in your SuperFX assembly files and you're good to go.

Lots of pseudo instructions added for readability, optimized to use `with` and implicit Sreg/Dreg where appropriate. (Sreg = source register, Dreg = destination register)

Here are a few examples (semi-colons separate statements)

| Pseudo instruction | Generated instructions |
| --- | --- |
| `add r1, r2, r3` | `to r1; from r2; add r3` |
| `sub r0, r0, r1` | `sub r1` |
| `sub r0, r1, r0` | `from r1; sub r0` |
| `mult r1, r1, #4` | `with r1; mult #4` |
| `div2 r1, r4` | `to r1; from r4; div2` |
| `rol r1` | `with r1; rol` |
| `hib r1, r0` | `to r1; hib` |
| `fmult r1, r1, r6` | `with r1; fmult` |
| `fmult r1, r6, r6` | `to r1; from r6; fmult` |
| `lmult r1, r4, r0, r6` | `to r1; lmult` |
| `getb r1` | `with r1; getb` |

Basically works how you'd expect a RISC to behave (see mips, arm instruction
sets).  
Generally, any instruction which uses Dreg AND Sreg AND has one operand can take up to 3 operands as a pseudo-instruction.  
Instructions which use Dreg AND Sreg but have no operand can take up to 2
operands.  
Instructions which use either Dreg OR Sreg can take up to one operand.

The `fmult` and `lmult` syntax probably begs for an explanation.  
These instructions use r6 as an implicit source operand, it is only added to the
pseudo-instruction for clarity.  
`lmult` also uses r4 as an implicit destination (low word of 32-bit result), what it boils down to is `lmult high (can't be r4), low (must be r4), Sreg, Sreg2 (at least one Sreg must be r6)`.  
`fmult` is the same except it only has one destination register (upper word of
32-bit result).

All of the basic instructions are still available.


Use the autonop "directive" to have the assembler automatically insert a `nop` opcode after `jal`, `ret` and `pop r15` pseudo-ops.
