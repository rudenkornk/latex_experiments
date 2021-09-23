$pdf_mode = 1;
$out_dir = "build";
$pdflatex = 'internal fix_paths_and_run lualatex --shell-escape -file-line-error %O %S';
sub fix_paths_and_run {
  my @args = ();
  @args = ();
  for my $i(@_) {
    $i =~ s/\\/\//g;
    $i =~ s/^(-[\w|-]*?directory[\w|-]*?=)(.*)/$1\"$2\"/;
    push @args, $i;
  }
  $args[-1] = "\"${args[-1]}\"";
  my $command = "";
  for my $i(@args) {
    $command = "${command} ${i}";
  }
  print "Command: ${command}\n";
  system $command;
}

@default_files = glob("images/*.tex");
push @default_files, "example.tex";
