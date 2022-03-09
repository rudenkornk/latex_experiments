#!/usr/bin/env python3

import sys
import glob
from lxml import objectify
from pathlib import Path
import argparse

def is_drawio_image(image_path: Path):
    with open(image_path, "rb") as f:
        parsed_xml = objectify.fromstring(f.read())
    if parsed_xml.tag == "mxfile":
        return True
    return False

def get_drawio_images(images_dir: Path):
    return [f for f in glob.glob(str(images_dir) + "/*.xml") if is_drawio_image(f)]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Check if there are drawio images to compile",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-i", "--images_dir", type=Path, dest="images_dir", required=True,
                        help="Directory with images to check")
    args = parser.parse_args(sys.argv[1:])
    images_dir = args.images_dir
    if get_drawio_images(images_dir):
        print(1)

