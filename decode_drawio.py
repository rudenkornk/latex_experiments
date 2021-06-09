import argparse
from pathlib import Path
import re, sys
import zlib, base64
from lxml import etree, objectify
from urllib.parse import unquote


def decode_diagram(diagram):
    decoded_64 = base64.b64decode(diagram)
    decoded_zlib = zlib.decompress(decoded_64, -zlib.MAX_WBITS)
    decoded_utf = decoded_zlib.decode('utf-8')
    decoded_url = unquote(decoded_utf)
    decoded_xml = etree.fromstring(decoded_url)
    formatted_xml = etree.tounicode(decoded_xml, pretty_print=True)
    return formatted_xml


def extract_diagram(contents):
    parsed_xml = objectify.fromstring(contents)
    if not (parsed_xml.tag == "mxfile" and hasattr(parsed_xml, "diagram")):
        return None
    return str(parsed_xml.diagram)


parser = argparse.ArgumentParser(description="Decode and format draw.io (app.diagrams.net) files",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i", "--input", type=Path, dest="input", required=True,
                    help="input file")
parser.add_argument("-o", "--output", type=Path, dest="output", help="output file")
parser.add_argument("-c", "--check", dest="check", action="store_true",
                    help="check if drawio file needs decoding")

args = parser.parse_args(sys.argv[1:])
input: Path = args.input
output: Path = args.output
is_check = args.check
with open(input, "r") as f:
    contents = f.read()
encoded_diagram = extract_diagram(contents)
if not encoded_diagram:
    if not is_check:
        print("Not an encoded .drawio file")
    sys.exit()
if is_check:
    sys.exit(1)
result = decode_diagram(encoded_diagram)
if output:
    with open(output, "w") as f:
        f.write(result)
else:
    print(result)
