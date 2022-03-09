#!/usr/bin/env python3

import os, sys
from pathlib import Path

def error(message):
    sys.stdout.flush()
    sys.stderr.write("error: %s\n" % message)
    sys.exit(1)

def check_path(path: Path):
    try:
        path.exists()
    except OSError as e:
        error(str(e))


def check_exists(path: Path, name: str):
    check_path(path)
    if not path.exists():
        error("Path for {} does not exist: {}".format(name, str(path)))


def check_file_if_exists(path: Path, name: str):
    check_path(path)
    if path.exists() and path.is_dir():
        error("Path for {} exists but it is a directory: {}".format(name, str(path)))


def check_dir_if_exists(path: Path, name: str):
    check_path(path)
    if path.exists() and not path.is_dir():
        error("Path for {} exists but it is not a directory: {}".format(name, str(path)))

def get_script_path():
    return Path(os.path.dirname(os.path.realpath(__file__)))

