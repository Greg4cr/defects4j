#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Fixes the assertThrownBy("<evosuite>") bug

trials=30
faults=15
criteria="default"
projects="Mockito"
exp_dir=`pwd`

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for (( fault=15 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each criteria
		for criterion in $criteria; do
			echo "-----Criterion: "$criterion
			# For each trial
			for (( trial=1; trial <= $trials ; trial++ )); do
				echo "-----Trial #"$trial
				cd "working/suites/"$project"_"$fault"/"$project"/evosuite-"$criterion"/"$trial"/"
				#Unpack
				tar xvjf $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2"

				find . -name "*.java" -type f -exec /home/greg/svn/defects4j/framework/experiment/fix_evosuite_command.sh {} \; 
				#Repack
				mv $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2" $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2.bak2"
				tar cvjf $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2" "org/" 
				rm -rf "org/"
				cd $exp_dir	
			done
		done
	done
done
