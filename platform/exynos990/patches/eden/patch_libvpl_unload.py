#!/usr/bin/env python3
# Copyright (c) 2026 3q5i
# SPDX-License-Identifier: Apache-2.0
# Originally written for fixing camera issues on One UI 8.5
# on Exynos 2100-based Samsung devices.
# This script patches libvpl.so by making vplUnload() return immediately,
# skipping the library's unload routine.
# Keep this copyright notice, license, and any NOTICE file when redistributing.

from __future__ import annotations

import argparse
import os
import struct
import sys
from dataclasses import dataclass
from typing import Iterable, List, Optional, Tuple


ELF_MAGIC = b"\x7fELF"
EI_CLASS = 4
EI_DATA = 5

ELFCLASS32 = 1
ELFCLASS64 = 2

ELFDATA2LSB = 1

EM_ARM = 40
EM_AARCH64 = 183

SHT_SYMTAB = 2
SHT_DYNSYM = 11

STT_FUNC = 2

PF_X = 0x1
PT_LOAD = 1


@dataclass
class ProgramHeader:
    p_type: int
    p_offset: int
    p_vaddr: int
    p_filesz: int
    p_memsz: int
    p_flags: int


@dataclass
class SectionHeader:
    sh_name: int
    sh_type: int
    sh_offset: int
    sh_size: int
    sh_link: int
    sh_entsize: int


@dataclass
class Symbol:
    name: str
    value: int
    size: int
    info: int
    shndx: int

    @property
    def type(self) -> int:
        return self.info & 0x0F


class ElfError(Exception):
    pass


class ElfFile:
    def __init__(self, path: str):
        self.path = path
        with open(path, "rb") as f:
            self.data = f.read()

        if self.data[:4] != ELF_MAGIC:
            raise ElfError(f"{path}: not an ELF file")

        self.elf_class = self.data[EI_CLASS]
        self.endianness = self.data[EI_DATA]
        if self.endianness != ELFDATA2LSB:
            raise ElfError(f"{path}: only little-endian ELF is supported")

        self.endian = "<"

        if self.elf_class == ELFCLASS64:
            self._parse64()
        elif self.elf_class == ELFCLASS32:
            self._parse32()
        else:
            raise ElfError(f"{path}: unknown ELF class {self.elf_class}")

    def _parse32(self) -> None:
        hdr = struct.unpack_from(
            self.endian + "16sHHIIIIIHHHHHH", self.data, 0
        )
        (
            _e_ident,
            _e_type,
            self.e_machine,
            _e_version,
            _e_entry,
            e_phoff,
            e_shoff,
            _e_flags,
            _e_ehsize,
            e_phentsize,
            e_phnum,
            e_shentsize,
            e_shnum,
            _e_shstrndx,
        ) = hdr

        self.program_headers: List[ProgramHeader] = []
        for i in range(e_phnum):
            off = e_phoff + i * e_phentsize
            ph = struct.unpack_from(self.endian + "IIIIIIII", self.data, off)
            (
                p_type,
                p_offset,
                p_vaddr,
                _p_paddr,
                p_filesz,
                p_memsz,
                p_flags,
                _p_align,
            ) = ph
            self.program_headers.append(
                ProgramHeader(p_type, p_offset, p_vaddr, p_filesz, p_memsz, p_flags)
            )

        self.section_headers: List[SectionHeader] = []
        for i in range(e_shnum):
            off = e_shoff + i * e_shentsize
            sh = struct.unpack_from(self.endian + "IIIIIIIIII", self.data, off)
            (
                sh_name,
                sh_type,
                _sh_flags,
                _sh_addr,
                sh_offset,
                sh_size,
                sh_link,
                _sh_info,
                _sh_addralign,
                sh_entsize,
            ) = sh
            self.section_headers.append(
                SectionHeader(sh_name, sh_type, sh_offset, sh_size, sh_link, sh_entsize)
            )

    def _parse64(self) -> None:
        hdr = struct.unpack_from(
            self.endian + "16sHHIQQQIHHHHHH", self.data, 0
        )
        (
            _e_ident,
            _e_type,
            self.e_machine,
            _e_version,
            _e_entry,
            e_phoff,
            e_shoff,
            _e_flags,
            _e_ehsize,
            e_phentsize,
            e_phnum,
            e_shentsize,
            e_shnum,
            _e_shstrndx,
        ) = hdr

        self.program_headers = []
        for i in range(e_phnum):
            off = e_phoff + i * e_phentsize
            ph = struct.unpack_from(self.endian + "IIQQQQQQ", self.data, off)
            (
                p_type,
                p_flags,
                p_offset,
                p_vaddr,
                _p_paddr,
                p_filesz,
                p_memsz,
                _p_align,
            ) = ph
            self.program_headers.append(
                ProgramHeader(p_type, p_offset, p_vaddr, p_filesz, p_memsz, p_flags)
            )

        self.section_headers = []
        for i in range(e_shnum):
            off = e_shoff + i * e_shentsize
            sh = struct.unpack_from(self.endian + "IIQQQQIIQQ", self.data, off)
            (
                sh_name,
                sh_type,
                _sh_flags,
                _sh_addr,
                sh_offset,
                sh_size,
                sh_link,
                _sh_info,
                _sh_addralign,
                sh_entsize,
            ) = sh
            self.section_headers.append(
                SectionHeader(sh_name, sh_type, sh_offset, sh_size, sh_link, sh_entsize)
            )

    def _read_cstr(self, blob: bytes, offset: int) -> str:
        end = blob.find(b"\x00", offset)
        if end == -1:
            end = len(blob)
        return blob[offset:end].decode("utf-8", errors="replace")

    def iter_symbols(self) -> Iterable[Symbol]:
        for sh in self.section_headers:
            if sh.sh_type not in (SHT_SYMTAB, SHT_DYNSYM):
                continue
            if sh.sh_entsize == 0:
                continue
            if sh.sh_link >= len(self.section_headers):
                continue

            strtab_sh = self.section_headers[sh.sh_link]
            strtab = self.data[strtab_sh.sh_offset : strtab_sh.sh_offset + strtab_sh.sh_size]

            count = sh.sh_size // sh.sh_entsize
            for i in range(count):
                off = sh.sh_offset + i * sh.sh_entsize
                if self.elf_class == ELFCLASS64:
                    st_name, st_info, _st_other, st_shndx, st_value, st_size = (
                        struct.unpack_from(self.endian + "IBBHQQ", self.data, off)
                    )
                else:
                    st_name, st_value, st_size, st_info, _st_other, st_shndx = (
                        struct.unpack_from(self.endian + "IIIBBH", self.data, off)
                    )
                name = self._read_cstr(strtab, st_name)
                yield Symbol(name, st_value, st_size, st_info, st_shndx)

    def find_symbol(self, name: str) -> Symbol:
        candidates = [
            sym for sym in self.iter_symbols() if sym.name == name and sym.type == STT_FUNC
        ]
        if not candidates:
            raise ElfError(f"{self.path}: symbol {name!r} not found")
        # Prefer non-zero-sized symbols.
        candidates.sort(key=lambda s: (s.size == 0, s.value))
        return candidates[0]

    def vaddr_to_offset(self, vaddr: int) -> int:
        for ph in self.program_headers:
            if ph.p_type != PT_LOAD:
                continue
            if not (ph.p_flags & PF_X):
                continue
            start = ph.p_vaddr
            end = ph.p_vaddr + ph.p_filesz
            if start <= vaddr < end:
                return ph.p_offset + (vaddr - ph.p_vaddr)
        raise ElfError(f"{self.path}: cannot map vaddr 0x{vaddr:x} to file offset")


def build_patch(elf: ElfFile, sym: Symbol) -> Tuple[int, bytes, str]:
    if elf.e_machine == EM_AARCH64:
        file_off = elf.vaddr_to_offset(sym.value)
        return file_off, b"\xc0\x03\x5f\xd6", "AArch64 ret"

    if elf.e_machine == EM_ARM:
        is_thumb = bool(sym.value & 1)
        code_addr = sym.value & ~1
        file_off = elf.vaddr_to_offset(code_addr)
        if is_thumb:
            # bx lr ; nop
            return file_off, b"\x70\x47\x00\xbf", "ARM Thumb bx lr ; nop"
        return file_off, b"\x1e\xff\x2f\xe1", "ARM bx lr"

    raise ElfError(f"{elf.path}: unsupported machine {elf.e_machine}")


def hexdump_bytes(blob: bytes) -> str:
    return " ".join(f"{b:02x}" for b in blob)


def patch_file(path: str, symbol_name: str, dry_run: bool) -> int:
    elf = ElfFile(path)
    sym = elf.find_symbol(symbol_name)
    patch_off, patch_bytes, patch_desc = build_patch(elf, sym)
    current = elf.data[patch_off : patch_off + len(patch_bytes)]

    print(f"file       : {path}")
    print(f"symbol     : {sym.name}")
    print(f"virt addr  : 0x{sym.value:x}")
    print(f"size       : {sym.size}")
    print(f"file off   : 0x{patch_off:x}")
    print(f"arch patch : {patch_desc}")
    print(f"current    : {hexdump_bytes(current)}")
    print(f"patched    : {hexdump_bytes(patch_bytes)}")

    if current == patch_bytes:
        print("status     : already patched")
        return 0

    if dry_run:
        print("status     : dry-run only, no changes written")
        return 0

    patched = bytearray(elf.data)
    patched[patch_off : patch_off + len(patch_bytes)] = patch_bytes
    with open(path, "wb") as f:
        f.write(patched)
    print("status     : patched")
    return 0


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Patch libvpl.so so vplUnload() immediately returns."
    )
    parser.add_argument("library", help="Path to libvpl.so")
    parser.add_argument(
        "--symbol",
        default="vplUnload",
        help="Function symbol to patch (default: vplUnload)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be patched without writing changes",
    )
    return parser.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)
    try:
        return patch_file(args.library, args.symbol, args.dry_run)
    except ElfError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    except FileNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
