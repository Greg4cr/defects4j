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
suites=10

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

				# TODO Identify smallest suite size and coverage level				
				covTarget=100
				sizeTarget=15
	
				# Use that matrix to prepare test suites.
				mkdir $working_dir"/suiteSpace/suites/"
				matrices=`ls $working_dir"/suiteSpace/matrices/"`
				for matrix in $matrices; do
					echo $matrix
					python OptiSuite.py -m $working_dir"/suiteSpace/matrices/"$matrix -n $suites -c $covTarget -s $sizeTarget -r 0.2 -t 0.2 -x 0.5 -z $RANDOM -a "OP" -p 100 -b 100 -q 25
					mv suites.csv $working_dir"/suiteSpace/suites/listing.csv" 
				done

				# TODO Assemble test classes from listing

				#rm -rf $working_dir"/suiteSpace"
			done
		done
	done
done


