#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Combine individual EvoSuite coverage matrices into a master matrix.

project=$1
fault=$2
trials=$3
criterion=$4
budget=$5
result_dir=$6
working_dir=$7

mkdir $working_dir"/suiteSpace/matrices/" 

# For each trial
for (( trial=1; trial <= $trials ; trial++ )); do
	# Get list of classes
	base=$result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial"/coverage_log/"$project"/evosuite-"$criterion"/"$fault"f/data/"
	classes=`ls $base`
	for class in $classes; do
		cat $base"/"$class"/"${criterion^^}"/matrix" | awk -v Class=$class -v Trial=$trial '
			BEGIN{
				test=-1;
				# Get EvoSuite classname
				split(Class,parts,".");
				size=0;
				for(p in parts){
					size++;
				}
				className=parts[size] "_ESTest.java";
			}
			{
				test++;
				# Get name of EvoSuite test
				testName="test";
				if(test<10){
					testName=testName "0" test "()";
				}else{
					testName=testName test "()";
				}
	
				# Convert EvoSuite matrix line from space-delimited to comma-delimited
				out=$0;
				gsub(" ",",",out);
				print className "," Trial "," testName "," substr(out,1,length(out)-2);
			}
		' >> $working_dir"/suiteSpace/matrices/"$class".csv"
	done
done
