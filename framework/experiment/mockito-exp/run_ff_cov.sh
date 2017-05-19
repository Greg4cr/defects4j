#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Runs fault-detection and coverage measurement for suites.

trials=15
faults=17
criteria="evosuite-default randoop"
projects="Mockito"
result_dir="working/results/"

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for (( fault=12 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each criteria
		for criterion in $criteria; do
			echo "-----Criterion: "$criterion
			# For each trial
			for (( trial=1; trial <= $trials ; trial++ )); do
				echo "-----Trial #"$trial
				mkdir /tmp/resultSpace
				perl ../bin/run_bug_detection.pl -p $project -d "working/suites/"$project"_"$fault"/"$project"/"$criterion"/"$trial"/" -o $result_dir -f "**/*Test.java" -t /tmp/resultSpace
				perl ../bin/run_coverage.pl -p $project -d "working/suites/"$project"_"$fault"/"$project"/"$criterion"/"$trial"/" -o $result_dir -f "**/*Test.java" -t /tmp/resultSpace
				rm -rf /tmp/resultSpace
			done
		done
	done

#	echo "--------------------------"
#	echo "Generating data"
	
#	./generate_isolated_tests.sh $result_dir >> $result_dir"test_log.csv"
#	./generate_coverage_log.sh $result_dir >> $result_dir"cov_log.csv"
#	mkdir $result_dir"/filteredRandoopResults/"

	# For each fault
#	for (( fault=1 ; fault <= $faults ; fault++ )); do
#		echo "-----Fault #"$fault
		# For each trial
#		for (( trial=1; trial <= $trials ; trial++ )); do
#			echo "-----Trial #"$trial
#				gawk -f filter_randoop.awk -v Trigger=../projects/Mockito/trigger_tests/$fault -v TestList=$result_dir"/isolated_tests/randoop/"$fault"b."$trial".log" -v Traces=$result_dir"/bug_detection_log/"$project"/randoop/"$fault"b."$trial".trigger.log" >> $result_dir"/filteredRandoopResults/"$fault"b."$trial".filter.log"
#		done
#	done	
done
