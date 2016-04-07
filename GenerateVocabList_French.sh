#!/bin/bash

## input list of words
## see post https://www.douban.com/note/530300843/
csv_input=$1
if [ -z "$csv_input" ]; then
  csv_input=`pwd`/fr_vocab_linguee_10k.csv
fi
if [ ! -f "$csv_input" ]; then
  url_base=http://www.linguee.fr/french-english/topfrench
  for url in ${url_base}/1-200.html ${url_base}/201-1000.html ${url_base}/1001-2000.html echo $(for i in `seq 2001 100 10000`; do  echo ${url_base}/${i}-$((i+99)).html; done); do
    curl -s $url | hxnormalize -l 240 -x 2>/dev/null | hxselect -s '\n' -c 'table tr td a' | iconv -f iso-8859-15 -t UTF-8 | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' 
    sleep 4s
  done > $csv_input 
fi

# remove duplication caused by articles l', le, la, les, un, une
csv_temp=${csv_input%.csv}_temp.csv
awk '{if(NF==1){sub(/^l'"'"'/, "", $1);}print $0;}' $csv_input | awk '{if(NF==2){if($1=="le"||$1=="la"||$1=="les"||$1=="un"||$1=="une"){print $2}else{print $0}}else{print $0}}' | nl | sort -k 2 | uniq -f 1 | sort -n -k1 | cut -f 2- > $csv_temp

# remove duplicated lemma
paste <(nl $csv_temp | awk '{if(NF==2){print $1}}' ) <( awk '{if(NF==1){print $0}}' $csv_temp | MElt -L 2>/dev/null |  awk -F/ '{if($3 ~"*"||$3=="cln"){print $1}else{print $3}}' ) > ${csv_input%.csv}_lemma.txt

csv_processed=${csv_input%.csv}_processed.csv
nl $csv_temp | while read line; do line_no=`echo $line | awk '{print $1}'`; lemma=`awk -v l=$line_no '{if($1==l){print $2}}' ${csv_input%.csv}_lemma.txt `; if [ -n "${lemma}" ]; then echo $line_no $lemma; else  echo $line; fi; done | sort -k 2 | uniq -f 1 | sort -n -k1 | cut -d ' ' -f 2- > $csv_processed
rm $csv_temp ${csv_input%.csv}_lemma.txt

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
  head -n $n $csv_processed | tail -n +$n0 | sort -R | split -l 100 - $DIR_TEMP/x
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
