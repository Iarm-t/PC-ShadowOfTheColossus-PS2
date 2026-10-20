"""Find candidate world-position float triples changed between two .state RAM dumps.

Usage: python Tools/find_walk_delta.py <fileA> <fileB>
A = "after walking" state, B = "standing" state. Prints aligned runs where
three consecutive float slots all changed plausibly like a position.
"""
import struct
import sys

MAGIC = b"2XSTATE1\x00"


def ram(path):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == struct.pack("<Q", 0x3145544154535832), "not a ps2x state"
    # header: magic(8) version(4) tick(4) -> ram follows tag block; find EMEM tag
    idx = data.find(b"EMEM")
    assert idx >= 0
    size = struct.unpack_from("<I", data, idx + 4)[0]
    return data[idx + 8 : idx + 4 + 4 + size]


def isf(v):
    import math

    return math.isfinite(v) and 0.02 < abs(v) < 30000.0


def main():
    a = ram(sys.argv[1])
    b = ram(sys.argv[2])
    n = min(len(a), len(b)) // 4
    fa = struct.unpack_from("<%df" % n, a)
    fb = struct.unpack_from("<%df" % n, b)

    hits = 0
    i = 0
    while i + 2 < n:
        dx = fa[i] - fb[i]
        dy = fa[i + 1] - fb[i + 1]
        dz = fa[i + 2] - fb[i + 2]
        if (
            isf(fa[i])
            and isf(fb[i])
            and isf(fa[i + 1])
            and isf(fb[i + 1])
            and isf(fa[i + 2])
            and isf(fb[i + 2])
            and (abs(dx) > 0.05 or abs(dz) > 0.05)
            and abs(dy) < 12.0
            and abs(dx) < 200.0
            and abs(dz) < 200.0
        ):
            print(
                "0x%07x (+%d): A=(%.3f, %.3f, %.3f) B=(%.3f, %.3f, %.3f) d=(%.3f, %.3f, %.3f)"
                % (i * 4, abs(dx), fa[i], fa[i + 1], fa[i + 2], fb[i], fb[i + 1], fb[i + 2], dx, dy, dz)
            )
            hits += 1
            i += 3
            continue
        i += 1
    print("candidate triples:", hits)


if __name__ == "__main__":
    main()
