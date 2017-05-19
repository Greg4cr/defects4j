#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Fixes a minor issue where tests from multiple suites got combined.

trials=30
faults=12
criteria="default branch line output weakmutation exception method methodnoexception"
projects="Mockito"
exp_dir=`pwd`

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
				cd "working/suites/"$project"_"$fault"/"$project"/evosuite-"$criterion"/"$trial"/"
				#Unpack
				tar xvjf $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2"

				#Delete anything that is not the current criteria
				for cri in $criteria; do
					if [ $cri != $criterion ]; then
						echo $cri","$criterion
						find . -name "*_"$cri"_*" -type f -delete
					fi
				done
				#Repack
				rm $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2"
				tar cvjf $project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2" "org/" 
				rm -rf "org/"
				cd $exp_dir	
			done
		done
	done
done
