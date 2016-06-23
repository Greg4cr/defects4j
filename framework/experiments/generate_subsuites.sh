#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate test suites from a pool of EvoSuite-generated test cases.

trials=10
faults=2
criteria="weakmutation" #default branch line output weakmutation exception method methodnoexception"
projects="Lang"
budgets="120"
exp_dir=`pwd`
result_dir=$exp_dir"/results/"
working_dir="/tmp"

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for (( fault=2 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each search budget
		for budget in $budgets; do
			echo "----Search Budget: "$budget	
			# Generate EvoSuite tests
			for criterion in $criteria; do
				echo "----Criterion: "$criterion
				mkdir $working_dir"/suiteSpace"
					# For each trial
					for (( trial=1; trial <= $trials ; trial++ )); do
						# Unzip each suite
						mkdir $working_dir"/suiteSpace/"$trial
						tar xvjf $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial"/"$project"-"$fault"f-evosuite-"$criterion"."$trial".tar.bz2" -C $working_dir"/suiteSpace/"$trial
					done	

				# Create master matrix
				./prepare_coverage_matrix.sh $project $fault $trials $criterion $budget $result_dir $working_dir	

				#rm -rf $working_dir"/suiteSpace"
			done
		done
	done
done


