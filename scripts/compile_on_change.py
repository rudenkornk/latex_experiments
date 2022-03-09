#!/usr/bin/env python3

from utils import check_path, check_exists, check_file_if_exists
import argparse
import ast
from pathlib import Path
import hashlib
import sys, os


def load_hashes(path: Path):
    hashes = {}
    if path.exists():
        with open(path, "r") as f:
            contents = f.read()
            hashes = ast.literal_eval(contents)
    return hashes


def store_hashes(path: Path, hashes):
    with open(path, "w") as f:
        f.write(str(hashes))


def compute_hash(path: Path) -> str:
    with open(path, "rb") as f:
        file_hash = hashlib.sha1()
        while chunk := f.read(8192):
            file_hash.update(chunk)
        return file_hash.hexdigest()


def _is_compilation_required(inp: Path, output: Path, hashes):
    input_hash = compute_hash(inp)
    if output and not output.exists():
        return True
    elif str(inp) not in hashes or input_hash != hashes[str(inp)]:
        return True
    else:
        return False


def is_compilation_required(inp: Path, output: Path, hashes_path: Path):
    check_exists(inp, "input")
    check_file_if_exists(inp, "input")
    if output:
        check_file_if_exists(output, "output")
    check_file_if_exists(hashes_path, "hashes_file")
    hashes = load_hashes(hashes_path)
    return _is_compilation_required(inp, output, hashes)


def update_hash(inp: Path, hashes_path: Path):
    check_exists(inp, "input")
    check_file_if_exists(inp, "input")
    check_file_if_exists(hashes_path, "hashes_file")
    hashes = load_hashes(hashes_path)
    hashes[str(inp)] = compute_hash(inp)
    store_hashes(hashes_path, hashes)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check if compilation of file is needed.",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-i", "--input", type=Path, dest="input", required=True,
                        help="path to source file")
    parser.add_argument("-o", "--output", type=Path, dest="output",
                        help="provide output file to compile if it does not exist")
    parser.add_argument("-u", "--update-hash", dest="update", action="store_true",
                        help="update file hash")
    parser.add_argument("-s", "--hashes-file", type=Path, dest="hashes", default="build/hashes.txt",
                        help="file to store hashes")

    args = parser.parse_args(sys.argv[1:])

    if args.update:
        update_hash(args.input, args.hashes)
    else:
        if is_compilation_required(args.input, args.output, args.hashes):
            print(1)

