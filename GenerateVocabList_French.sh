#!/bin/bash

## input list of words
## see post https://www.douban.com/note/530300843/
csv_input=$1
if [ -z "$csv_input" ]; then
  csv_input=`pwd`/fr_vocab_linguee_10k.csv
fi
if [ ! -f "$csv_input" ]; then
  for url in http://www.linguee.fr/french-english/topfrench/1-200.html http://www.linguee.fr/francais-anglais/topfrench/201-1000.html http://www.linguee.fr/francais-anglais/topfrench/1001-2000.html echo $(for i in `seq 2001 100 10000`; do  echo http://www.linguee.fr/french-english/topfrench/${i}-$((i+99)).html; done); do

    curl -s $url | hxnormalize -l 240 -x 2>/dev/null | hxselect -s '\n' -c 'table tr td a' | iconv -f iso-8859-15 -t UTF-8 | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' 

    sleep 4s
  done > $csv_input 
fi

DIR_OUTPUT=$(realpath `dirname $csv_input`)
DIR_CURRENT=`pwd`
cd $DIR_OUTPUT

i=1
n0=1
for n in 200 1000 2000 5000 10000; do
  tag=`echo $n | awk '{printf "%.0f\n", $1/100}' | awk '{print $1/10"k"}' `
  if [ $n -lt 1000 ]; then
    tag=$n
  fi
  DIR_TEMP=$DIR_OUTPUT/$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)
  mkdir $DIR_TEMP
  head -n $n $csv_input | tail -n +$n0 | sort -R | split -l 100 - $DIR_TEMP/x
  for file in $DIR_TEMP/x*; do
    temp_tex=$DIR_TEMP/tabular_${tag}_`zeropad $i 3`.tex
    doc_tex=$DIR_OUTPUT/fr_vocab_linguee_${tag}_`zeropad $i 3`.tex
    sort $file -o $file
    csv2latex --nohead --longtable --nohlines --novlines $file > $temp_tex

    cat > $doc_tex <<EOF
\documentclass{article}

\usepackage{fontspec}
\usepackage{polyglossia}
\setdefaultlanguage{french}

\usepackage{longtable}
\usepackage{array}
\begin{document}
\setlength{\LTleft}{0pt}
EOF
    cat $temp_tex >> $doc_tex
    echo "\end{document}" >> $doc_tex
    xelatex $doc_tex
    rm ${doc_tex%.tex}.log ${doc_tex%.tex}.aux
    i=$((i+1))
  done
  n0=$((n+1))
  rm $DIR_TEMP -rf
done

cd $DIR_CURRENT
