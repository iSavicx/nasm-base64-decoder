# nasm-base64-decoder
A base64 decoder writen in assembly.

The program reads 4 base 64 encoded bytes at a time, converts to ascii and printes the result in 3bytes to standard output.


Input to the program can be either given via the command line or from an inputfile
e.g: ./base64decoder < inputfile

Program only works if the input is base64 encoded