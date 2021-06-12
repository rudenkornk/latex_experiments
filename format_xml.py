import argparse
from pathlib import Path
import re, sys
import zlib, base64
from lxml import etree


def format_xml(contents):
    decoded_xml = etree.fromstring(contents)
    formatted_xml = etree.tounicode(decoded_xml, pretty_print=True)
    return formatted_xml


parser = argparse.ArgumentParser(description="Pretty-print xml files",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i", "--input", type=Path, dest="input", required=True,
                    help="input file")
parser.add_argument("-o", "--output", type=Path, dest="output", help="output file")

args = parser.parse_args(sys.argv[1:])
input: Path = args.input
output: Path = args.output
with open(input, "r") as f:
    contents = f.read()
formatted_xml = format_xml(contents)
if output:
    with open(output, "w") as f:
        f.write(formatted_xml)
else:
    print(formatted_xml)
