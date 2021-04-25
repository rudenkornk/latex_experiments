#!/usr/bin/env sh

# Originally from https://github.com/latex3/latex3

# A minimal current TL is installed adding only the packages that are required

# See if there is a cached version of TL available
export PATH=/tmp/texlive/bin/x86_64-linux:$PATH
if ! command -v texlua > /dev/null; then
  # Obtain TeX Live
  wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  tar -xzf install-tl-unx.tar.gz
  cd install-tl-20*

  # Install a minimal system
  ./install-tl --profile=../texlive.profile

  cd ..
fi

# Sometimes tlmgr needs to be updated before we can install packages
tlmgr update --self

# Just including texlua so the cache check above works
tlmgr install luatex

# Base tools to compile
tlmgr install texliveonfly latexmk

# texliveonfly does not detect the following packages automatically
tlmgr install biber
tlmgr install minted fvextra upquote lineno xstring framed caption
tlmgr install collection-langcyrillic
tlmgr install collection-langeuropean
tlmgr install collection-fontsrecommended

# Fixed set of packages for tex images:
tlmgr install geometry pgfplots jknapltx

# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0

# Update the TL install but add nothing new
tlmgr update --self --all --no-auto-install
