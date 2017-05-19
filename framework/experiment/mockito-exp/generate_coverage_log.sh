#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generates a CSV of coverage from Cobertura logs.

# $1 = result directory

project="Mockito"
suites="evosuite-default randoop"
faults=17

echo "Project,Test Source,Fault,Trial,Lines Covered,Lines Total,Line Coverage,Branches Covered,Branches Total,Branch Coverage"
for suite in $suites; do
	for (( fault=1 ; fault <= $faults ; fault++ )); do

		files=`ls $1"/coverage_log/"$project"/"$suite"/" | grep ".xml" | grep $fault"f"`
		numFiles=`ls $1"/coverage_log/"$project"/"$suite"/" | grep ".xml" | grep $fault"f" | wc -l`
		avgLC=0
		avgLT=0
		avgLCOV=0
		avgBC=0
		avgBT=0
		avgBCOV=0

		for file in $files; do
			trial=`echo $file | cut -d"." -f 2`
			lc=`head -4 $1"/coverage_log/"$project"/"$suite"/"$file | tail -1 | cut -d" " -f 4 | cut -d"\"" -f 2`
			lt=`head -4 $1"/coverage_log/"$project"/"$suite"/"$file | tail -1 | cut -d" " -f 5 | cut -d"\"" -f 2`
			bc=`head -4 $1"/coverage_log/"$project"/"$suite"/"$file | tail -1 | cut -d" " -f 6 | cut -d"\"" -f 2`
			bt=`head -4 $1"/coverage_log/"$project"/"$suite"/"$file | tail -1 | cut -d" " -f 7 | cut -d"\"" -f 2`
			lcov=`bc <<< 'scale=2; '$lc'/'$lt`
			bcov=`bc <<< 'scale=2; '$bc'/'$bt`

			echo $project","$suite","$fault","$trial","$lc","$lt","$lcov","$bc","$bt","$bcov

			avgLC=$(($avgLC+$lc))
			avgLT=$(($avgLT+$lt))
			avgLCOV=`bc <<< 'scale=2; '$avgLCOV'+'$lcov`
			avgBC=$(($avgBC+$bc))
			avgBT=$(($avgBT+$bt))
			avgBCOV=`bc <<< 'scale=2; '$avgBCOV'+'$bcov`
		done

		if [ "$numFiles" -gt "0" ]; then
			avgLC=`bc <<< 'scale=2; '$avgLC'/'$numFiles`
			avgLT=`bc <<< 'scale=2; '$avgLT'/'$numFiles`
			avgLCOV=`bc <<< 'scale=2; '$avgLCOV'/'$numFiles`
			avgBC=`bc <<< 'scale=2; '$avgBC'/'$numFiles`
			avgBT=`bc <<< 'scale=2; '$avgBT'/'$numFiles`
			avgBCOV=`bc <<< 'scale=2; '$avgBCOV'/'$numFiles`
			echo $project","$suite","$fault",Average,"$avgLC","$avgLT","$avgLCOV","$avgBC","$avgBT","$avgBCOV
		fi
	done
done

