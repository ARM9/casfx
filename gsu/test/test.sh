ca65 pseudo.asm && ld65 -C lorom.cfg pseudo.o -o pseudo.bin
ca65 raw.asm && ld65 -C lorom.cfg raw.o -o raw.bin
ca65 errors.asm 2> errors.out

#echo "Pseudo instructions"
#cat pseudo.bin | gsudis
#echo "Raw instructions"
#cat raw.bin | gsudis

cmp errors.out errors.expected

cmp -b pseudo.bin raw.bin
