#!/bin/bash

project=$1
faults=$2
buildFolder=$3
working=$4

mkdir class_lists
mkdir "class_lists/"$project
mkdir "class_lists/"$project"/all_classes"

for ((fault=22; fault<=$faults; fault++)); do
	defects4j checkout -p $project -v $fault"f" -w "/tmp/"$project"_"$fault
	cd "/tmp/"$project"_"$fault
	defects4j compile
	find "/tmp/"$project"_"$fault"/"$buildFolder -type f -name "*.class" >> tempList
	cat tempList | awk -v Where=$buildFolder '{
		split($0,parts,Where);
		gsub(/\//,".",parts[2]);
		cName = substr(parts[2],2,length(parts[2])-7);
		print cName;
	}' >> $fault".src"
	mv $fault".src" $working"/class_lists/"$project"/all_classes/"
	cd $working
	rm -rf "/tmp/"$project"_"$fault
done
