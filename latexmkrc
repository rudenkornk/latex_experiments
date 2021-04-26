$pdf_mode = 1;
$out_dir = "build";
$pdflatex = "internal custom_pdflatex %O %S";
sub custom_pdflatex {
  my @args = ();
  @args = ();
  push @args, "pdflatex";
  push @args, "--synctex=1";
  push @args, "--shell-escape";
  push @args, "--interaction=nonstopmode";
  for my $i(@_){
    $i =~ s/\\/\//;
    $i =~ s/^(-[\w|-]*?directory[\w|-]*?=)(.*)/$1\"$2\"/;
    push @args, $i;
  }
  $args[-1] = "\"${args[-1]}\"";
  my $command = "";
  for my $i(@args){
    $command = "${command} ${i}"
  }
  print "Command: ${command}\n";
  system $command;
}

@default_files = ();
push @default_files, "images/picture_source.tex";
push @default_files, "example.tex";
