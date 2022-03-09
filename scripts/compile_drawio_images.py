#!/usr/bin/env python3

import os, sys, platform
import glob
from pathlib import Path
from compile_on_change import is_compilation_required, update_hash
from check_drawio_images import get_drawio_images
from utils import get_script_path
import argparse

def get_drawio_exec_name():
    if platform.system() == "Windows":
        return "draw.io"
    else:
        return "drawio"

def check_drawio_installed():
    drawio_check_command = get_drawio_exec_name() + " --help "
    drawio_check_command += ">nul" if platform.system() == "Windows" else ">/dev/null"
    error = os.system(drawio_check_command)
    if error:
        print("Looks like drawio package is not installed or not added to Path")
        print("You can download it from https://github.com/jgraph/drawio-desktop/releases")
        sys.exit(error)

def run_xserver_if_needed():
    if platform.system() == "Linux":
        if "DISPLAY" not in os.environ:
            os.environ["DISPLAY"] = ":0"
        run_xserver_path = get_script_path() / "run_xserver.sh"
        error = os.system("bash " + str(run_xserver_path))
        if error:
            sys.exit(error)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Compile drawio images",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-b", "--build_dir", type=Path, dest="build_dir", default="build",
                        help="Build directory")
    parser.add_argument("-i", "--images_dir", type=Path, dest="images_dir", default="images",
                        help="Directory with images to compile")
    args = parser.parse_args(sys.argv[1:])
    build_dir = args.build_dir
    images_dir = args.images_dir
    hashes_path = build_dir / "hashes.txt"

    images_paths = get_drawio_images(images_dir)
    if not images_paths:
        print("No drawio images to compile")
        exit()

    run_xserver_if_needed()
    check_drawio_installed()

    drawio_exec = get_drawio_exec_name()
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    for filename in images_paths:
        inp = Path(filename)
        output = build_dir / (inp.name[:-4] + ".pdf")
        if not is_compilation_required(inp, output, hashes_path):
            print("Recompilation for {} is omitted".format(inp))
            continue
        command = drawio_exec + " --transparent --crop --export --output {} {}".format(output, inp)
        print(command)
        error = os.system(command)
        if error:
            print("Unexpected error when running drawio command")
            sys.exit(error)
        update_hash(inp, hashes_path)
