#!/bin/bash
subs=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/sublist_include.txt
outfile=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/nsi_summary.txt

echo -e "sub\tmean_nsi" > "$outfile"

while read -r sub; do
  json=nsi_sub${sub}/sub${sub}_nsi_summary.json
  mean=$(grep mean_nsi "$json" | sed 's/[^0-9.]*//g')
  echo -e "${sub}\t${mean}" >> "$outfile"
done < "$subs"

awk 'NR>1{sum+=$2;n++} END{print "grand mean_nsi:", sum/n}' "$outfile"