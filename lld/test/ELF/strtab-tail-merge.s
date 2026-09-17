# REQUIRES: x86
# RUN: split-file %s %t
# RUN: llvm-mc -filetype=obj -triple=x86_64 %t/a.s -o %t/a.o
# RUN: llvm-mc -filetype=obj -triple=x86_64 %t/b.s -o %t/b.o

## String tail merging is always applied to .dynstr, which is bounded by the
## number of dynamic symbols: `bar` shares the storage of `foo_bar`.
# RUN: ld.lld -shared %t/a.o %t/b.o -o %t/a.so
# RUN: llvm-readelf -x .dynstr %t/a.so | FileCheck %s --check-prefix=DYNSTR
# RUN: llvm-readelf --dyn-syms %t/a.so | FileCheck %s --check-prefix=DYNSYM

# DYNSTR:      Hex dump of section '.dynstr':
# DYNSTR-NEXT: 0x{{[0-9a-f]+}} 00666f6f 5f626172 00
# DYNSYM:      foo_bar
# DYNSYM:      bar

## .strtab is deduplicated and tail merged: `local` (defined in both files)
## and `bar` share the storage of `main_local` and `foo_bar`.
# RUN: ld.lld %t/a.o %t/b.o -o %t/a
# RUN: llvm-readelf -x .strtab %t/a | FileCheck %s --check-prefix=MERGE
# RUN: ld.lld -O2 %t/a.o %t/b.o -o %t/a.o2
# RUN: llvm-readelf -x .strtab %t/a.o2 | FileCheck %s --check-prefix=MERGE

# MERGE:      Hex dump of section '.strtab':
# MERGE-NEXT: 0x00000000 00666f6f 5f626172 006d6169 6e5f6c6f
# MERGE-NEXT: 0x00000010 63616c00

## Symbols still resolve to the correct names.
# RUN: llvm-readelf -s %t/a | FileCheck %s --check-prefix=SYMS
# SYMS:      main_local
# SYMS:      local
# SYMS:      foo_bar
# SYMS:      bar

## -r: the synthesized STT_FILE names are merged as well.
# RUN: ld.lld -r %t/a.o %t/b.o -o %t/a.ro
# RUN: llvm-readelf -p .strtab %t/a.ro | FileCheck %s --check-prefix=RO

# RO:        [     1]  foo_bar
# RO-NEXT:   [     9]  b.o
# RO-NEXT:   [     d]  a.o
# RO-NEXT:   [    11]  main_local

#--- a.s
.global foo_bar
foo_bar:
main_local:
local:
  ret
.global bar
bar:
  ret

#--- b.s
main_local:
local:
  ret