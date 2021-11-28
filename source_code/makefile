# makefile for task
task: main.o input.o inrnd.o output.o perimeter.o heapsort.o
	gcc -g -o task main.o input.o inrnd.o output.o perimeter.o heapsort.o -no-pie
main.o: main.asm macros.mac
	nasm -f elf64 -g -F dwarf main.asm -l main.lst
input.o: input.asm
	nasm -f elf64 -g -F dwarf input.asm -l input.lst
inrnd.o: inrnd.asm
	nasm -f elf64 -g -F dwarf inrnd.asm -l inrnd.lst
output.o: output.asm
	nasm -f elf64 -g -F dwarf output.asm -l output.lst
perimeter.o: perimeter.asm
	nasm -f elf64 -g -F dwarf perimeter.asm -l perimeter.lst
heapsort.o: heapsort.asm
	nasm -f elf64 -g -F dwarf heapsort.asm -l heapsort.lst
