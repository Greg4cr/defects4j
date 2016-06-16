#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate tests to find real faults in Mockito

trials=1
faults=2
criteria="line" #default branch line output weakmutation exception method methodnoexception"
projects="Lang"
budgets="120"
exp_dir=`pwd`
result_dir=$exp_dir"/results"
working_dir="/tmp"

mkdir $result_dir

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for (( fault=2 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each trial
		for (( trial=1; trial <= $trials ; trial++ )); do
			echo "-----Trial #"$trial
			# For each search budget
			for budget in $budget; do
				echo "----Search Budget: "$budget	
				# Generate EvoSuite tests
				for criterion in $criteria; do
					mkdir $working_dir"/genSpace"
					echo "-----Generating EvoSuite tests for "$criterion
					# Add configuration ID to evo config
					cp ../util/evo.config evo.config.backup
                       	        	echo "-Dconfiguration_id=evosuite-"$criterion"-"$trial >> ../util/evo.config

					perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/genSpace" -D
					mv evo.config.backup ../util/evo.config
					cat evosuite-report/statistics.csv >> $result_dir"/suites/"$project"_"$fault"/"$budget"/generation-statistics.csv"
					rm -rf evosuite-report
					rm -rf $working_dir"/genSpace/"
				done

				# Detect and remove non-compiling tests
				suites=`ls $result_dir"/suites/"$project"_"$fault"/"$project"/"`
				mkdir $working_dir"/tempResults"
				for suite in $suites; do
					echo $suite
					echo "-----Checking to see if suite needs fixed: "$suite
					perl ../util/fix_test_suite.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/"$suite"/"$trial -t $working_dir"/tempResults"
				done
				rm -rf $working_dir"/tempResults"
			done
		done
	done
done
