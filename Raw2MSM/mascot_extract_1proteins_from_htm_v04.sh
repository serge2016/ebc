#!/bin/bash

#   Script for extracting Protein IDs from Mascot output (htm). Previous krist03.sh
#
# Autor: Serge I. Mitrofanov.
# Last modification: 28.08.2015

mainDir=~/Kristina2_2015_2/
outFile=${mainDir}Cancer_3summ.htm

rm -rf $mainDir*_long*; rm -rf $mainDir*_shor*; rm -rf $mainDir*_medi*; rm -rf $outFile

#echo -n "Processing: "
for file in ${mainDir}F*.htm; do
	fname="${file##*/}"
	name="${fname%%.*}"
	dir="${file%/*}/"
#	echo -n "$name "
	origFile="`grep "MS data file" $file | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/' | tr ":" " " | sed 's/\\\\/\//g'`"
	origTime="`grep "Timestamp" $file | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/'`"
	echo "File: ${origFile}. Time: ${origTime}."
	cat "$file" | sed -e :a -e '$!N;s/\n//;ta' | sed -e 's|</TBODY>||gi' -e 's|<TBODY>||gi' | sed -e 's/<HR>/\n/g' -e 's/<P>/<P>\n/g' | egrep -i '<FONT COLOR=#FF0000><B>' | sed -e 's/&nbsp;//g' | tee "${dir}${name}_long.htm" | sed -e 's/<B>Proteins matching the same set of *peptides:/\n<B>Gomologi:/gi' | sed -e 's/<A HREF=[^>]*>[^<]*<\/A>//gi' | sed  's/^<TABLE /&\n/;s/.*\n/SERGE/;/SERGE/s/<TABLE /\n&/;s/\n.*//;s/SERGE/<TABLE /i' | sed -e 's/<\/TABLE><TABLE/SERGE/i;s/^.*SERGE/Gomologi:\n<TABLE/i' | sed -e '/<B><\/B>/s/<\/TR>/<\/TR>\n/gi' | sed -e '/<B><\/B>/d' -e 's/Gomologi:/<table>/i' | tee "${dir}${name}_medi.htm" | sed -e 's|<TD NOWRAP>.*<B>Score:</B>\(.*\)<B>Queries.*<TD NOWRAP>|<td>\1</td><TD>|gi' | sed -e 's|<[/]*TT>||gi' -e 's/Tax_Id=.*Gene_Symbol=//i' | sed -e '/^<table>$/,/<\/TABLE>/s/^.*NOWRAP>\([^<]*\)<.*$/\1___ /i' -e 's/^<table>$/<TD>(/i' -e 's|</TR></TABLE>$|<TD></TD></TR></TABLE>|i' -e 's|^</TABLE>$|)</TD></TR></TABLE>|i' | sed -e :a -e '$!N;s/\n//;ta' | sed -e 's|<TD></TD></TR></TABLE><TD>|<TD>|gi' | sed -e 's/, )/)/gi' -e 's/ BORDER=0 CELLSPACING=0//gi' -e 's/ cellSpacing=0 border=0//gi' -e 's|<[/]*B>||gi' -e 's|<[/]*A[^>]*>||gi' | sed -e 's|</TABLE><TABLE>||gi' -e 's|<TR>|\n<TR>|gi' -e 's|</TABLE>|\n</TABLE>|i' > "${dir}${name}_shor.htm"
	cat "${dir}${name}_shor.htm" | sed -e 's|^<TR>\(.*\)$| '"<TR><TD>${origFile}</TD><TD>${origTime}</TD>"'\1|' > "${dir}${name}_shor2.htm"
done
echo ""

echo "" > $outFile
for file in $mainDir*_shor2.htm; do
	cat $file >> $outFile
done