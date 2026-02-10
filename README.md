# Hack assembler.

Overly complicated hack assembler as it supports any spacing:

```asm
M =1;JLT
D  =  M;JNE
A  =D&A;  JEQ
MD  =  D-1; JGT
```

And it also has a built in logger that sometimes gives you debug info about your
mistakes; Sometimes as I was too lazy to add it in all cases.

```cmd
error: UnexpectedCharacter, on line 2:
D / =D|M;JMP ...
  ^
```

## Files

The codebase is structured to have all of the parts and the stages of an
assembler in different files, so if you are looking for the first pass then it's
of course in [firstPass.zig](firstPass.zig).

There is also the [instruction.zig](instruction.zig) that has all of the
"language" definations needed for hack.

Most important are:

- [parser.zig](parser.zig)
- [firstPass.zig](firstPass.zig)
- [secondPass.zig](secondPass.zig)
- [instruction.zig](instruction.zig)
