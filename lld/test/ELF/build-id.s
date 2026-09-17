# REQUIRES: x86

# RUN: llvm-mc -filetype=obj -triple=x86_64-unknown-linux %s -o %t

# RUN: ld.lld --build-id %t -o %t2
# RUN: llvm-readobj -S %t2 | FileCheck -check-prefix=ALIGN %s

# RUN: ld.lld --build-id %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s
# RUN: ld.lld --build-id %t -o %t2 --threads=1
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s

# RUN: ld.lld --build-id=fast %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=FAST %s

# RUN: ld.lld --build-id=md5 %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=MD5 %s
# RUN: ld.lld --build-id=md5 %t -o %t2 --threads=1
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=MD5 %s

# RUN: ld.lld --build-id=sha1 %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s
# RUN: ld.lld --build-id=sha1 %t -o %t2 --threads=1
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s

# RUN: ld.lld --build-id=tree %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s
# RUN: ld.lld --build-id=tree %t -o %t2 --threads=1
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s

# RUN: ld.lld --build-id=uuid %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=UUID %s

# RUN: ld.lld --build-id=0x12345678 %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=HEX %s

# RUN: ld.lld %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=NONE %s

# RUN: ld.lld --build-id=md5 --build-id=none %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=NONE %s
# RUN: ld.lld --build-id --build-id=none %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=NONE %s
# RUN: ld.lld --build-id=none --build-id %t -o %t2
# RUN: llvm-objdump -s %t2 | FileCheck --check-prefix=SHA1 %s

.globl _start
_start:
  nop

.section .note.test, "a", @note
   .quad 42

# ALIGN:      Name: .note.gnu.build-id
# ALIGN-NEXT: Type: SHT_NOTE
# ALIGN-NEXT: Flags [
# ALIGN-NEXT:   SHF_ALLOC
# ALIGN-NEXT: ]
# ALIGN-NEXT: Address:
# ALIGN-NEXT: Offset: [[_:0x[0-9A-Z]*(0|4|8|C)$]]
# ALIGN-NEXT: Size:
# ALIGN-NEXT: Link:
# ALIGN-NEXT: Info:
# ALIGN-NEXT: AddressAlignment: 4

# FAST:      Contents of section .note.test:
# FAST:      Contents of section .note.gnu.build-id:
# FAST-NEXT: 04000000 08000000 03000000 474e5500  ............GNU.
# FAST-NEXT: c0bbb38d 43f5cc4c

# MD5:      Contents of section .note.gnu.build-id:
# MD5-NEXT: 04000000 10000000 03000000 474e5500  ............GNU.
# MD5-NEXT: e0abec31 73d5bb71 05f5e27f 4d5afad7

# SHA1:      Contents of section .note.gnu.build-id:
# SHA1-NEXT: 04000000 14000000 03000000 474e5500  ............GNU.
# SHA1-NEXT: 30a42fc8 7d65f522 d810d8f1 9b0a06f7

# UUID:      Contents of section .note.gnu.build-id:
# UUID-NEXT: 04000000 10000000 03000000 474e5500  ............GNU.

# HEX:      Contents of section .note.gnu.build-id:
# HEX-NEXT: 04000000 04000000 03000000 474e5500  ............GNU.
# HEX-NEXT: 12345678

# NONE-NOT: Contents of section .note.gnu.build-id:

# RUN: ld.lld --build-id=sha1 -z separate-loadable-segments %t -o %t2
# RUN: llvm-readelf -x .note.gnu.build-id %t2 | FileCheck --check-prefix=SEPARATE %s

# SEPARATE:      Hex dump of section '.note.gnu.build-id':
# SEPARATE-NEXT: 0x00200198 04000000 14000000 03000000 474e5500
# SEPARATE-NEXT: 0x002001a8 9b2db9a1 0b6b21a9 4f45631e 824ac2ad

# RUN: ld.lld --build-id=sha1 --no-rosegment %t -o %t2
# RUN: llvm-readelf -x .note.gnu.build-id %t2 | FileCheck --check-prefix=NORO %s

# NORO:      Hex dump of section '.note.gnu.build-id':
# NORO-NEXT: 0x00200160 04000000 14000000 03000000 474e5500
# NORO-NEXT: 0x00200170 0328ea02 3763c298 6d518d46 1ea43766
