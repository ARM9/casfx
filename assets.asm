
.rodata

torus_sans:
	.incbin "gfx/torus_sans.chr"
torus_sans_size = * - torus_sans

sfx_pal:
	.incbin "gfx/colours.pal"

block_gfx:
	.incbin "gfx/block.chr"
block_gfx_size = * - block_gfx