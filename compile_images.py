import os, sys, platform
import glob
from lxml import etree, objectify
from pathlib import Path
from compile_on_change import is_compilation_required, update_hash

build_dir = Path("build")

# Set drawio executable name
if platform.system() == "Windows":
    drawio = "draw.io"
else:
    drawio = "drawio"

# Check that xserver is running on linux
if platform.system() == "Linux":
    if "DISPLAY" not in os.environ:
      os.environ["DISPLAY"] = ":0"
    error = os.system("bash ./run_xserver.sh")
    if error:
        sys.exit(error)

# Check that draw.io installed
drawio_check_command = drawio + " --help "
drawio_check_command += ">nul" if platform.system() == "Windows" else ">/dev/null"
error = os.system(drawio_check_command)
if error:
    print("Looks like drawio package is not installed or not added to Path")
    print("You can download it from https://github.com/jgraph/drawio-desktop/releases")
    sys.exit(error)

if not os.path.exists(build_dir):
    os.makedirs(build_dir)

for filename in glob.glob("images/*.xml"):
    inp = Path(filename)
    with open(inp, "rb") as f:
        parsed_xml = objectify.fromstring(f.read())
    # Check that this xml file is actually drawio file
    if parsed_xml.tag != "mxfile":
        continue
    output = build_dir / (inp.name[:-4] + ".pdf")
    if not is_compilation_required(inp, output):
        print("Recompilation for {} is omitted".format(inp))
        continue
    command = drawio + " --transparent --crop --export --output {} {}".format(output, inp)
    print(command)
    error = os.system(command)
    if error:
      print("Unexpected error when running drawio command")
      sys.exit(error)
    update_hash(inp)
