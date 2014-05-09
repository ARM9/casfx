
.macro dbg_BlockSize start
	; useful for making sure that things fit in cache
	.out .concat(.string(start), " size: ", .string(* - start), " bytes.")
.endmacro

.macro MakeLabel fooz, barz
	.ident(.sprintf("%s%s", .string(fooz), .string(barz))):
.endmacro

