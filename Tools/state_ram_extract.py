#!/usr/bin/env python3
"""Extract the EE RAM block from a .state file (ps2x savestate) and diff two RAM images.

State file layout (ps2x/state_io.h + EeScheduler::serializeMachine):
  <u64 magic><u32 version><u64 tick> "EMEM" <rdram 32 MiB> <scratchpad 16 KiB> <iop 2 MiB> ...
"""
import struct
import sys

RAM_SIZE = 32 * 1024 * 1024
HEADER = 8 + 4 + 8 + 4  # magic, version, tick, "EMEM" tag


def state_ram(path):
    with open(path, "rb") as f:
        head = f.read(HEADER + 16)
        magic, version, tick = struct.unpack_from("<QII", head, 0)
        tag = head[20:24]
        if magic != 0x3145544154535832 or tag != b"EMEM":
            raise SystemExit("%s: not a ps2x savestate (magic %016x tag %r)" % (path, magic, tag))
        f.seek(HEADER)
        return f.read(RAM_SIZE)


def ranges(diffs, min_len):
    out = []
    for a in diffs:
        if out and a == out[-1][1] + 1:
            out[-1][1] = a
        else:
            out.append([a, a])
    return [(s, e) for s, e in out if e - s + 1 >= min_len]


def main():
    if len(sys.argv) < 3:
        raise SystemExit("usage: state_ram_extract.py <fileA> <fileB> [min-range-bytes]")
    a = state_ram(sys.argv[1]) if sys.argv[1].endswith(".state") else open(sys.argv[1], "rb").read()
    b = state_ram(sys.argv[2]) if sys.argv[2].endswith(".state") else open(sys.argv[2], "rb").read()
    if len(a) != len(b):
        raise SystemExit("size mismatch %d vs %d" % (len(a), len(b)))
    words = struct.unpack("<%dI" % (len(a) // 4), a)
    words2 = struct.unpack("<%dI" % (len(b) // 4), b)
    diffs = [i for i, (x, y) in enumerate(zip(words, words2)) if x != y]
    print("differing words: %d of %d" % (len(diffs), len(words)))
    min_len = int(sys.argv[3]) if len(sys.argv) > 3 else 16
    total = 0
    for s, e in ranges(diffs, min_len):
        total += (e - s + 1) * 4
        fa = ["%08x" % words[i] for i in range(s, min(s + 3, e + 1))]
        fb = ["%08x" % words2[i] for i in range(s, min(s + 3, e + 1))]
        print("0x%06x-0x%06x (%6d B)  A:%s..  B:%s.." % (s * 4, e * 4, (e - s + 1) * 4, " ".join(fa), " ".join(fb)))
    print("bytes in shown ranges: %d" % total)


if __name__ == "__main__":
    main()
