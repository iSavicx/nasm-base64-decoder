base64decoder: base64decoder.o
	ld -o base64decoder base64decoder.o

base64decoder.o: base64decoder.asm
	nasm -f elf64 -g -F dwarf base64decoder.asm -l base64decoder.lst

clean:
	rm -f base64decoder base64decoder.o base64decoder.lst
