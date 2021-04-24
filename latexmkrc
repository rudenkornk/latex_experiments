$pdf_mode = 1;
$out_dir = 'build';
$aux_dir = 'build/logs';
$latex = 'latex %O  --shell-escape %S';
$pdflatex = 'pdflatex -synctex=1 --shell-escape %O %S';
@default_files = ();
push @default_files, 'images/picture_source.tex';
push @default_files, 'example.tex';
