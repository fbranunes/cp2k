#!/usr/bin/env python3

# author: Ole Schuett

import os
import sys
from subprocess import check_output
from os import path
from glob import glob

KNOWN_EXTENSIONS = (
    "F",
    "c",
    "cu",
    "cpp",
    "cxx",
    "cc",
)


# =============================================================================
def main():
    if len(sys.argv) != 4:
        print("Usage: check_archives.py <ar-executable> <src-dir> <lib-dir>")
        sys.exit(1)

    ar_exe = sys.argv[1]
    src_dir = sys.argv[2]
    lib_dir = sys.argv[3]

    known_archives = set()
    for root, dirs, files in os.walk(src_dir):
        if "PACKAGE" in files:
            content = open(path.join(root, "PACKAGE"), encoding="utf8").read()
            package = eval(content)

            archive = "libcp2k" + path.basename(root)
            if "archive" in package.keys():
                archive = package["archive"]

            archive_fn = path.join(lib_dir, archive + ".a")
            known_archives.add(archive_fn)
            if not path.exists(archive_fn):
                continue

            file_parts = [fn.rsplit(".", 1) for fn in files]
            src_basenames = [
                parts[0] for parts in file_parts if parts[-1] in KNOWN_EXTENSIONS
            ]

            output = check_output([ar_exe, "t", archive_fn], encoding="utf8")
            for line in output.strip().split("\n"):
                if line == "__.SYMDEF SORTED":
                    continue  # needed for MacOS
                assert line.endswith(".o")
                if line[:-2] not in src_basenames:
                    print(
                        "Could not find source for object %s in archive %s , removing archive."
                        % (line, archive_fn)
                    )
                    os.remove(archive_fn)
                    break

    rogue_archives = set(glob(path.join(lib_dir, "*.a"))) - known_archives
    for archive_fn in rogue_archives:
        print("Found rogue archive %s , removing archive." % (archive_fn))
        os.remove(archive_fn)


# =============================================================================
main()
