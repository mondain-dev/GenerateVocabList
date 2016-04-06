#!/bin/bash

## input list of words
## see post https://www.reddit.com/r/russian/comments/289wba/10000_most_common_russian_words_in_spreadsheet/
csv_input=$1

DIR_OUTPUT=`dirname $csv_input`

DIR_CURRENT=`pwd`
cd $DIR_OUTPUT

i=1
n0=301
for n in 3000 5000 10000; do
  tag=`echo $n | awk '{printf "%.0f\n", $1/100}' | awk '{print $1/10"k"}' `
  DIR_TEMP=$DIR_OUTPUT/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
  mkdir $DIR_TEMP
  cat $csv_input | head -n $n | tail -n +$n0 | sort -R | split -l 100 - $DIR_TEMP/x
  for file in $DIR_TEMP/x*; do
    temp_tex=$DIR_TEMP/tabular_${tag}_`zeropad $i 3`.tex
    doc_tex=$DIR_OUTPUT/Rus_vocab_${tag}_`zeropad $i 3`.tex
    sort $file -o $file
    csv2latex --nohead --longtable --nohlines --novlines $file > $temp_tex
    sed -i 's/\//\\slash /g' $temp_tex
    sed -i 's/|/\\,\\textbar\\,/g' $temp_tex
    sed -i 's/\\begin{longtable}{lll/\\begin{longtable}{L{3cm}L{4cm}L{5cm}/' $temp_tex

    cat > $doc_tex <<EOF
\documentclass[a4paper,12pt]{report}
\usepackage{fontspec}
\usepackage{polyglossia}
\setdefaultlanguage{russian}
\setmainfont{Times New Roman}
\usepackage{longtable}
\usepackage{array}
\newcolumntype{L}[1]{>{\raggedright\let\newline\\ \arraybackslash\hspace{0pt}}p{#1}}
\begin{document}
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
