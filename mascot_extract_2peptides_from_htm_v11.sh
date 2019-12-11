#!/bin/bash

#   Script for extracting peptides from several mascot output *.htm files and merging into one summary. Now extracting peptides instead of proteins (krist03.sh and earlier).
# perl and python3 are necessary
#
# Autor: Serge I. Mitrofanov.
# Last modification: 21.11.2018 09:20


SOFT="$HOME/soft"
# cd $SOFT
# On the official support site http://www.matrixscience.com/mascot_support_v2_6.html there is an "update", that contains scripts for conversion from DAT to HTM.
# wget "http://www.matrixscience.com/downloads/mascot_2_6_02_patch_x86_64-linux.tar.bz2" -O "mascot_2_6_02_patch_x86_64-linux.tar.bz2"
# tar --one-top-level -xjf mascot_2_6_02_patch_x86_64-linux.tar.bz2
MASCOTCGIDIR="$SOFT/mascot_2_6_02_patch_x86_64-linux/cgi"


BaseD="$HOME/EBC"
PEPTS2SVODN="$BaseD/mascot_pepts_to_svodn_v03.py"



#.../MASCOT_DATA/<sampleName>/<sampleName>_<N><format>/<*.htm files>
MASCOTDATADIR="$BaseD/MASCOT_DATA"
# This should be a directory with different not structured *.dat files even from different datasets
dirWithAllDATs="$MASCOTDATADIR/Mia2018/Mia2018_3dat"




#BaseDir=$BaseD/Serge_run008
#mkdir -p $BaseDir
currD=$(pwd)

msmDirSuffix="_2msm"
datDirSuffix="_3dat"
htmOnlyDirSuffix="_4htm"
htmDirSuffix="_4htm2_linux"
htmPeptDirSuffix="_4htmPepts_linux"
htmProtDirSuffix="_4htmProts_linux"
peptsDirSuffix="_5Pepts"
protsDirSuffix="_5ProtsPepts"
peptTmpSuffix="_pepts.txt.xls"
protTmpSuffix="_prots_pepts.txt.xls"
#protRedOnlyTmpSuffix="_prots_pepts_RedOnly.txt.xls"
peptsSummFileSuffix="_6PeptsSumm.txt.xls"
protsSummFileSuffix="_6ProtsPeptsSumm.txt.xls"

# Convert *.dat to *.htm: 0 - skip; 1 - run and put results into MASCOTDATADIR
runDatToHtmLinuxFLAG=0
# Etracting peptides from several mascot output *.htm files and merging them into one summary for dataset: 0 - skip; 1 - run and put results into MASCOTDATADIR
runExtractPeptsFLAG=1


renameAndMoveDATsAccordingToMsmFLAG=0
if [ $runDatToHtmLinuxFLAG -eq 1 ]; then
	cd $MASCOTCGIDIR
	echo "Working with '$dirWithAllDATs/*.dat' ..."
	for file in $dirWithAllDATs/*.dat; do
		if [[ -s "$file" ]]; then
			echo -n "Processing '$(basename "$file")' ..."
			msmFile="$(grep "^FILE=" $file | sed -e "s/^FILE=\(.*\)$/\1/" | tr '\\' '/' | tr -d '\r')"
			currProba="$(basename "$msmFile" | sed -e "s/^\(.*\).msm$/\1/")"
			currMsmDirName="$(basename "$(dirname "$msmFile")")"
			if [[ ! $currMsmDirName =~ $msmDirSuffix$ ]]; then
				echo "Warning! Current msm dir name ('$currMsmDirName') doesn't last with '$msmDirSuffix'."
			fi
			currDatasetDirName="$(basename "$(dirname "$(dirname "$msmFile")")")"
			if [[ "$currDatasetDirName$msmDirSuffix" != "$currMsmDirName" ]]; then
				echo "Warning! Current msm dir name ('$currMsmDirName') doesn't correspond to '$currDatasetDirName' + '$msmDirSuffix'."
			fi
			echo " $currDatasetDirName:$currProba"
			if [[ "$renameAndMoveDATsAccordingToMsmFLAG" -eq "1" ]]; then
				currOutDatDir="$MASCOTDATADIR/$currDatasetDirName/$currDatasetDirName$datDirSuffix"
				mkdir -p "$currOutDatDir"
				currDatFile="$currOutDatDir/$currProba.dat"
				if [[ -s "$currDatFile" ]]; then
					if [[ "$(cmp --silent $varscanAllHcFPFilteredFile $varscanAllHcFPFilteredFile_copy; echo $?)" -eq "0" ]]; then
						rm "$file"
					else
						echo "Warning. New dat file ('$file') is not equal to '$currDatFile'. Backuping."
						backup_time=$(date "+%Y%m%d.%H%M%S")
						mv "$currDatFile" "$currDatFile.$backup_time"
						mv "$file" "$currDatFile"
					fi
				else
					mv "$file" "$currDatFile"
				fi
				file="$currDatFile"
			fi
			currOutProtHtmDir="$MASCOTDATADIR/$currDatasetDirName/$currDatasetDirName$htmProtDirSuffix"
			mkdir -p "$currOutProtHtmDir"
			currHtmProtFile="$currOutProtHtmDir/$currProba.htm"
			if [[ ! -s "$currHtmProtFile" ]]; then
				perl master_results.pl file=$file > "$currHtmProtFile"
				if [[ ! -s "$currHtmProtFile" ]]; then
					echo "Error! File '$(basename "$file")' was not correctly converted to '$currHtmProtFile'."
				fi
			fi
			currOutPeptHtmDir="$MASCOTDATADIR/$currDatasetDirName/$currDatasetDirName$htmPeptDirSuffix"
			mkdir -p "$currOutPeptHtmDir"
			currHtmPeptFile="$currOutPeptHtmDir/$currProba.htm"
			if [[ ! -s "$currHtmPeptFile" ]]; then
				perl master_results.pl file=$file REPTYPE=peptide _sigthreshold=0.05 REPORT=AUTO _server_mudpit_switch=0.000000001 _ignoreionsscorebelow=0 _showsubsets=0 _showpopups=TRUE _sortunassigned=scoredown _requireboldred=0 > "$currHtmPeptFile"
				if [[ ! -s "$currHtmPeptFile" ]]; then
					echo "Error! File '$file' was not correctly converted to '$currHtmPeptFile'."
				fi
			fi
		else
			echo "Error. File '$file' doesn't exist or is empty."
		fi
	done
	cd $currD
fi

PATTERN="$MASCOTDATADIR/*"

if [ $runExtractPeptsFLAG -eq 1 ]; then
	echo "  Extracting peptides from several mascot output *.htm files and merging them into one summary for dataset ..."  
	echo "    Working with input dirs by pattern: $PATTERN."
	for dir in $PATTERN; do
		if [[ ! -d "$dir" ]]; then
			continue
		fi
		dir="$(basename $dir)"
		echo "    $dir"
		currOutPeptDir=$MASCOTDATADIR/$dir/$dir$peptsDirSuffix
		currOutProtDir=$MASCOTDATADIR/$dir/$dir$protsDirSuffix
		currDirSummPeptsfile=$MASCOTDATADIR/$dir$peptsSummFileSuffix
		currDirSummProtsfile=$MASCOTDATADIR/$dir$protsSummFileSuffix
		echo -e "#FileID\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide" > $currDirSummPeptsfile
		echo -e "#FileID\tHit Number\tProtein hit ID\tScore\tGene Symbol\tGene name\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tPeptide" > $currDirSummProtsfile
		mkdir -p $currOutPeptDir
		mkdir -p $currOutProtDir
		currInPeptDir=$MASCOTDATADIR/$dir/$dir$htmPeptDirSuffix
		#currInProtDir=$MASCOTDATADIR/$dir/$dir$htmProtDirSuffix
		# __htmOnly datasets (with protein reports, NOT peptide!)
		currInHtmOnlyDir=$MASCOTDATADIR/$dir/$dir$htmOnlyDirSuffix
		if [[ -d "$currInPeptDir/" || -d "${currInPeptDir%_linux}/" ]]; then
			if [[ -d "$currInPeptDir/" ]]; then
				echo "Working with HTM-files generated on Linux"
			else
				echo "Working with HTM-files generated in other place (Windows machine?)"
				currInPeptDir="${currInPeptDir%_linux}"
			fi
			for file in $currInPeptDir/*.htm; do
				if [[ -s "$file" ]]; then
					fname="${file##*/}"
					name="${fname%.*}"
					currPeptsFile="$currOutPeptDir/${name}$peptTmpSuffix"
					currProtsFile="$currOutProtDir/${name}$protTmpSuffix"
					#currProtsRedOnlyFile="$currOutProtDir/${name}$protRedOnlyTmpSuffix"
					origFile="`grep 'MS data file' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I' | tr ":" " " | sed 's/\\\\/\//g'`"
					origDatabase="`grep 'Database' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I'`"
					origTaxonomy="`grep 'Taxonomy' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I'`"
					origTime="`grep 'Timestamp' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I'`"
					echo -e "#File:\t$(basename $currInPeptDir)/$fname\tMS data file:\t${origFile}\tTimestamp:\t${origTime}" | tee "$currPeptsFile"
					echo -e "#FileID\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide" >> "$currPeptsFile"
					cat "$file" | tr -d '\r' | grep '<A HREF="peptide_view.pl' | grep '#FF0000' | sed -e 's|<[^>]*>||g' -e 's|&nbsp;|\t|g' -e 's|^  *||' -e "s/^\(.*\)$/${dir}\|${name}\t\1/" -e 's|\t\t*|\t|g' -e 's| + .*Oxidation.*$||' | tee -a "$currDirSummPeptsfile" >> "$currPeptsFile"
					
					echo -e "#File:\t$(basename $currInPeptDir)/$fname\tMS data file:\t${origFile}\tTimestamp:\t${origTime}" | tee "$currProtsFile"
					echo -e "#FileID\tHitNumber\tProteinHitID\tProteinHitDescription\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide\tRedOrBlack\tBoldOrNormal" >> "$currProtsFile"
					cat "$file" | tr -d '\r' \
  | sed -n -e '/<P><TABLE BORDER=0 CELLSPACING=0>/,/Peptide matches not assigned to protein/p' | sed -e 's/<P>//' -e '$ d' | sed -e 's/&nbsp;//g' \
  | sed -e '/<TR><TD><TT><B><A NAME/{N;s|<TR><TD><TT><B><A NAME="\([^"]*\)".*<TD NOWRAP>.*<A[^>]*>\([^<]*\)</A>.*Mass:</B>\([^<]*\)<B>Score:</B>\(.*\)<B>Queries.*<TD NOWRAP><TT>\([^<]*\)</TT></TD></TR>.*|\1\t\2\t\5; MASS=\3; SCORE=\4|gi;}' \
  | sed -e '/<TR><TD><TT><B><\/B><\/TT><\/TD><TD NOWRAP><TT>/{N;s|^.*<A[^>]*>\([^<]*\)</A>.*Mass:</B>\([^<]*\)<B>Score:</B>\(.*\)<B>Queries.*<TD NOWRAP><TT>\([^<]*\)</TT></TD></TR>.*|\t\1\t\4; MASS=\2; SCORE=\3|gi;}' \
  | sed -e '/<TR><TD><TT><B><A NAME/{s|<TR><TD><TT><B><A NAME="\([^"]*\)".*<TD NOWRAP>.*<A[^>]*>\([^<]*\)</A>.*<B>Score:</B>\(.*\)<B>Queries.*|\1\t\2\t-; SCORE=\3|gi;}' \
  | sed -e '/<TR><TD><TT><B><\/B><\/TT><\/TD><TD NOWRAP><TT>/{s|^.*<A[^>]*>\([^<]*\)</A>.*<B>Score:</B>\(.*\)<B>Queries.*|\t\1\t-; SCORE=\2|gi;}' \
  | sed -e 's|<INPUT TYPE="checkbox"[^>]*>||g'   -e 's/<A HREF=[^>]*>\([^<]*\)<\/A>/\1/gi'   -e 's|<[/]*TT>||gi'   -e 's|<TD[^>]*>|<TD>|gi'   -e 's|</*U>||Ig' \
  | sed -e 's|<FONT COLOR="\?#FF0000"\?>|<R>|Ig' -e 's|</FONT>|</R>|Ig' \
  | sed -e '/Check to include this hit in error tolerant/,/<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0>/d' -e '/^<\/TABLE>$/d' -e '/^<TABLE BORDER=0 CELLSPACING=0>$/d' -e '/<BR>/,/\(Proteins matching the same set of peptides\|<HR>\)/d' -e '/<HR>/d' -e '/<TD><B>Query<\/B><\/TD>/d' \
  | sed -e 's|> *|>|g'   -e 's| *<|<|g' \
  | sed -e 's| + .*Oxidation[^<]*<|<|' \
  | perl -pe 's|^<TR><TD></TD><TD>([0-9]*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)<TD>([^0-9]*)[0-9]*</TD></TR>$|\t\t\t$1\t$2\t$3\t$4\t$5\t$6\t$7\t$8\t$9\t$10|i' \
  | sed -e 's|^\(\t\t\t.*<R>.*\)$|\1\tred|I' -e '/^\t\t\t/ {/red$/! s|^\(.*\)$|\1\tblack|}' \
  | sed -e 's|^\(\t\t\t.*<B>.*\)$|\1\tbold|I' -e '/^\t\t\t/ {/bold$/! s|^\(.*\)$|\1\tnormal|}' \
  | sed -e 's|</*[A-Z]*>||Ig' -e 's|\([0-9]\)\.\([0-9]\)|\1,\2|g' \
  | sed -e "s|^\([^#].*\)$|${dir}\|${name}\t\1|" >> "$currProtsFile"
					echo -e "\n\n${dir}|${name}\tOTHER" >> "$currProtsFile"
					cat "$file" | tr -d '\r' \
  | sed -n -e '/Peptide matches not assigned to protein/,/&query=1&/p' | sed -e 's/<P>//' -e '$ d' | sed -e 's/&nbsp;//g' \
  | sed -e 's|<INPUT TYPE="checkbox"[^>]*>||g'   -e 's/<A HREF=[^>]*>\([^<]*\)<\/A>/\1/gi'   -e 's|<[/]*TT>||gi'   -e 's|<TD[^>]*>|<TD>|gi'   -e 's|</*U>||Ig' \
  | sed -e 's|<FONT COLOR="\?#FF0000"\?>|<R>|Ig' -e 's|</FONT>|</R>|Ig' \
  | sed -e '/^<\/TABLE>$/d' -e '/^<TABLE BORDER=0 CELLSPACING=0>$/d' -e '/<TD><B>Query<\/B><\/TD>/d' -e '/Peptide matches not assigned to protein/,/^<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0>$/d' \
  | sed -e 's|> *|>|g'   -e 's| *<|<|g' \
  | sed -e 's| + .*Oxidation[^<]*<|<|' \
  | perl -pe 's|^<TR><TD></TD><TD>([0-9]*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)</TD><TD>(.*)<TD>([^0-9]*)[0-9]*</TD></TR>$|\t\t\t$1\t$2\t$3\t$4\t$5\t$6\t$7\t$8\t$9\t$10|i' \
  | sed -e 's|^\(\t\t\t.*<R>.*\)$|\1\tred|I' -e '/^\t\t\t/ {/red$/! s|^\(.*\)$|\1\tblack|}' \
  | sed -e 's|^\(\t\t\t.*<B>.*\)$|\1\tbold|I' -e '/^\t\t\t/ {/bold$/! s|^\(.*\)$|\1\tnormal|}' \
  | sed -e 's|</*[A-Z]*>||Ig' -e 's|\([0-9]\)\.\([0-9]\)|\1,\2|g' \
  | sed -e "s|^\([^#].*\)$|${dir}\|${name}\t\1|" >> "$currProtsFile"
					
					#echo -e "#File:\t$(basename $currInPeptDir)/$fname\tMS data file:\t${origFile}\tTimestamp:\t${origTime}" | tee "$currProtsRedOnlyFile"
					#echo -e "#FileID\tHitNumber\tProteinHitID\tProteinHitDescription\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide\tRedOrBlack\tBoldOrNormal" >> "$currProtsRedOnlyFile"
					
				else
					echo "Warning. File '$file' doesn't exist or is empty."
				fi
			done
		elif [[ -d "$currInHtmOnlyDir/" ]]; then
			echo "      Warning! Dir '$dir' doesn't contain source files (detected by '_4htm' subdir)."
			for file in $currInHtmOnlyDir/*.htm; do
				if [[ -s "$file" ]]; then
					fname="${file##*/}"
					name="${fname%.*}"
					currPeptsFile="$currOutPeptDir/${name}$peptTmpSuffix"
					origFile="`grep 'MS data file' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I' | tr ":" " " | sed 's/\\\\/\//g'`"
					origTime="`grep 'Timestamp' "$file" | sed -e 's/^.*: \(.*\)<\/B>.*$/\1/I'`"
					echo -e "#File:\t$(basename $currInPeptDir)/$fname\tMS data file:\t${origFile}\tTimestamp:\t${origTime}" | tee "$currPeptsFile"
					echo -e "#FileID\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide" >> "$currPeptsFile"
					cat "$file" | tr -d '\r' | sed -ne '/<[Tt][Aa][Bb][Ll][Ee] [Cc][Ee][Ll][Ll][Ss][Pp][Aa][Cc][Ii][Nn][Gg]="\?0"\? [Bb][Oo][Rr][Dd][Ee][Rr]="\?0"\?>/,/<\/[Ff][Oo][Rr][Mm]>/ p' | sed -e '/<\/FORM>/Id' -e 's/&nbsp;//g' -e 's|</\?TT>||Ig' -e 's|<TD[^>]*>|<TD>|Ig' | sed -e '/^<[Bb][Rr]>$/,/^<[Hh][Rr]>$/d' | sed -e '/><B>Observed<\/B>/Id' | sed -e 's/^ *//' | sed -e :a -e '$!N;s/\n//;ta' | sed -e 's|<FONT COLOR="\?#FF0000"\?>|<R>|Ig' -e 's|</FONT>|</R>|Ig' | sed -e 's|</*U>||Ig' | sed -e 's|</TR>|</TR>\n|Ig' | sed -e 's/<A [^>]*HREF[^>]*>\([^<]*\)<\/A>/\1/Ig' | sed -e 's|^.*<TR><TD><B><A NAME="\?\([^">]*\)"\?>.*</TD><TD>\([^<]*\)<.*B>Score:</B>[<RB> ]*\([0-9]*\)<.*$|\1\t\2\t\3\t|I' | sed -e 's|</TR>|</TR>\n|Ig' | sed -e 's|^<TR><TD></TD><TD>\([0-9]*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>\(.*\)</TD><TD>.*<TD>\([^0-9]*\)[0-9]*</TD></TR>$|\t\t\t\t\t\1\t\2\t\3\t\4\t\5\t\6\t\7\t\8\t-\t\9<BR>|I' | sed -e '/<INPUT /Id' -e '/Queries matched:/Id' -e '/^$/d' -e '/<B>Query<\/B>/Id' -e '/<TR><TD><\/TD><TD><\/TD><\/TR>/Id' | sed -ne '/^Hit/,/^<\/TBODY>/ Ip' | sed -e '/<\/TBODY><\/TABLE>/Id' | sed -e 's|^<TR><TD></TD><TD>\(.*\)</TD></TR>$|\t\1<BR>|Ig' | sed -e 's| \[Homo sapiens\]||Ig' | sed -e :a -e '$!N;s/\n//;ta' | sed -e 's/<BR>/\n/Ig' | sed -e 's|^\(\t\t\t\t\t.*<R>.*\)$|\1\tred|I' -e '/^\t\t\t\t\t/ {/red$/! s|^\(.*\)$|\1\tblack|}' | sed -e 's|^\(\t\t\t\t\t.*<B>.*\)$|\1\tbold|I' -e '/^\t\t\t\t\t/ {/bold$/! s|^\(.*\)$|\1\tnormal|}' | sed -e 's|</*[A-Z]*>||Ig' | sed -e 's|\t *|\t|g' -e 's|\([0-9]\)\.\([0-9]\)|\1,\2|g' | sed -e "s|^\(.*\)$|${dir}\|${name}\t\1|" | awk 'BEGIN {FS="\t"} {if ($17 ~ /^red/) {print}}' | cut -d$'\t' -f-1,7-16 | tee -a "$currDirSummPeptsfile" >> "$currPeptsFile"
				else
					echo "Warning. File '$file' doesn't exist or is empty."
				fi
			done
		else
			echo "  Warning! No HTM subdirs to process..."
		fi
	done
fi

echo ""
dayToday=$(date "+%Y%m%d")
allDatasetsPeptsSvodiiFile=$MASCOTDATADIR/allDatasets_7summAllPepts_$dayToday.txt.xls
allDatasetsPeptsTableFile=$MASCOTDATADIR/allDatasets_8peptsTable_$dayToday.txt.xls
#"#Filename\tHit Number\tProtein hit ID\tScore\tGene Symbol\tGene name\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tPeptide\tRedOrBlack"
echo -e "#FileID\tQuery\tObserved\tMr(expt)\tMr(calc)\tppm\tMiss\tScore\tExpect\tRank\tPeptide" > $allDatasetsPeptsSvodiiFile
for file in $MASCOTDATADIR/*$peptsSummFileSuffix; do
	grep -v "^#" $file >> $allDatasetsPeptsSvodiiFile
done
echo ""
python3 $PEPTS2SVODN $allDatasetsPeptsSvodiiFile $allDatasetsPeptsTableFile
