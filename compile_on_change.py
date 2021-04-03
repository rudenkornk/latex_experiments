import argparse
import ast
from pathlib import Path
import hashlib
import sys
import os


def error(message):
    sys.stdout.flush()
    sys.stderr.write("error: %s\n" % message)
    sys.exit(1)


def check_path(path: Path):
    try:
        path.exists()
    except OSError as e:
        error(str(e))


def compute_hash(path: Path) -> str:
    with open(path, "rb") as file:
        file_hash = hashlib.sha1()
        while chunk := file.read(8192):
            file_hash.update(chunk)
        return file_hash.hexdigest()


def compile(inp: Path, out: Path, logs: Path, show_output: bool):
    assert not hasattr(compile, "invoked")
    compile.invoked = True
    command = "pdflatex -aux-directory \"{}\" -output-directory \"{}\" \"{}\"".format(logs, out, inp)
    supress_out = ""
    if os.name == 'nt':
        supress_out = " >nul"
    else:
        supress_out = " >/dev/null"
    if not show_output:
        command += supress_out
    else:
        sys.stdout.flush()
    os.system(command)


hashes_default = "$logs/hashes.txt"
parser = argparse.ArgumentParser(description="Compile LaTeX file on change.",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i", "--input", type=Path, dest="inputs", nargs="*", required=True,
                    help="paths to LaTeX files to compile")
parser.add_argument("-o", "--output", type=Path, dest="output", default="build",
                    help="output directory for pdf file")
parser.add_argument("--aux-directory", type=Path, dest="logs", default="build/logs",
                    help="directory for logs")
parser.add_argument("--hashes-file", type=str, dest="hashes", default=hashes_default,
                    help="file to store file hashes")
parser.add_argument("--on-output-change", dest="on_output_change", action="store_true",
                    help="also recompile if output file is changed")
parser.add_argument("-f", "--force", dest="force", action="store_true",
                    help="force recompilation")
parser.add_argument("-l", "--show-latex", dest="latex_output", action="store_true",
                    help="show LaTeX compiler output")
parser.add_argument("-v", "--verbose", dest="verbose", action="store_true",
                    help="show verbose messages")

args = parser.parse_args(sys.argv[1:])
out: Path = args.output
logs: Path = args.logs
compile_on_output_change: bool = args.on_output_change
force_recompilation: bool = args.force
verbose: bool = args.verbose
show_latex_output = args.latex_output


def log(message: str):
    if verbose:
        print(message)

# newline
log("")

check_path(out)
check_path(logs)

if args.hashes == hashes_default:
    hashes_file = logs / "hashes.txt"
else:
    hashes_file = Path(args.hashes)
    check_path(hashes_file)

if out.exists() and not out.is_dir():
    error("Output exists but it is not a directory: " + str(out))
if logs.exists() and not logs.is_dir():
    error("Logs directory exists but it is not a directory: " + str(logs))
if hashes_file.exists() and hashes_file.is_dir():
    error("File with hashes exists but it is a directory: " + str(hashes_file))

stored_hashes = {}
if hashes_file.exists():
    with open(hashes_file, "r") as file:
        contents = file.read()
        stored_hashes = ast.literal_eval(contents)
new_hashes = stored_hashes.copy()


def process_input(inp: Path):
    log("")
    log("Compiling LaTeX file \"{}\"...".format(str(inp)))

    check_path(inp)

    out_file = out / (inp.name[:-4] + ".pdf")

    if inp.name[-4:] != ".tex":
        error("Input filename should contain \".tex\" at the end: " + str(inp))
    if len(inp.name) <= 4:
        error("Input filename should have at least 1 letter in addition to \".tex\" ending: " + str(inp))
    if not inp.exists():
        error("Input file does not exist: " + str(inp))
    if inp.is_dir():
        error("Input file must be a file, not a directory: " + str(inp))
    if out_file.exists() and out_file.is_dir():
        error("Output file exists but it is a directory: " + str(out_file))

    new_hashes[str(inp)] = compute_hash(inp)
    log("Computed hash of input:  " + new_hashes[str(inp)])
    log("Stored hash of input:    " + (stored_hashes[str(inp)] if str(inp) in stored_hashes else "(not yet computed)"))
    log("")
    if compile_on_output_change:
        if out_file.exists():
            new_hashes[str(out_file)] = compute_hash(out_file)
        log("Computed hash of output: " + (new_hashes[
                                               str(out_file)] if str(
            out_file) in new_hashes else "(file does not exist)"))
        log("Stored hash of output:   " + (stored_hashes[
                                               str(out_file)] if str(
            out_file) in stored_hashes else "(not yet computed)"))
        log("")

    if force_recompilation:
        log("Recompilation is forced. Recompiling...")
        compile(inp, out, logs, show_latex_output)
    elif not out_file.exists():
        log("Output file does not exist. Recompiling...")
        compile(inp, out, logs, show_latex_output)
    elif str(inp) not in stored_hashes or new_hashes[str(inp)] != stored_hashes[str(inp)]:
        log("Stored input file hash differ from computed. Recompiling...")
        compile(inp, out, logs, show_latex_output)
    elif compile_on_output_change and (str(out_file) not in stored_hashes or stored_hashes[
        str(out_file)] != new_hashes[str(out_file)]):
        log("Stored output file hash differ from computed. Recompiling...")
        compile(inp, out, logs, show_latex_output)
    else:
        log("Recompilation is not required")

    if compile_on_output_change and out_file.exists():
        new_hashes[str(out_file)] = compute_hash(out_file)


for inp in args.inputs:
    process_input(Path(inp))

if new_hashes != stored_hashes:
    log("New hashes differ from stored. Saving new hashes to \"{}\"".format(str(hashes_file)))
    with open(hashes_file, "w") as file:
        file.write(str(new_hashes))
else:
    log("Hashes did not change")
