#!/bin/sh
set -ex
wget --no-check-certificate http://www.lri.fr/~filliatr/ftp/bibtex2html/bibtex2html-1.98.tar.gz
tar -xzvf bibtex2html-1.98.tar.gz
echo "+++++ CONFIGURE +++++"
cd bibtex2html-1.98 && ./configure --prefix=/usr && make 
echo "+++++ MAKE +++++"
make 
echo "+++++ MAKE INSTALL +++++"
sudo make install
echo "+++++ DONE +++++"
