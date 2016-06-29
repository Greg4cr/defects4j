#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate tests to find real faults in Defects4J Programs

# Set at command line
projects=$1
faults=$2
trials=$3
project_dir=$4"/defects4j/framework/projects"
all_classes=$5 #1 to generate tests for all loaded classes, 0 to only generate tests for patched classes

# Pre-configured
criteria="weakmutation default branch line output weakmutation exception method methodnoexception cbranch"
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
	for (( fault=1 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each trial
		for (( trial=1; trial <= $trials ; trial++ )); do
			echo "-----Trial #"$trial
			# For each search budget
			for budget in $budgets; do
				echo "----Search Budget: "$budget	
				# Generate EvoSuite tests
				for criterion in $criteria; do
					mkdir $working_dir"/genSpace"
					echo "-----Generating EvoSuite tests for "$criterion
					# Add configuration ID to evo config
					cp ../util/evo.config evo.config.backup
                       	        	echo "-Dconfiguration_id=evosuite-"$criterion"-"$trial >> ../util/evo.config

					if [ $all_classes -eq 1 ]; then
						echo "(all loaded classes)"
						perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/genSpace" -a 450 -A
					else
						echo "(only patched classes)"
						perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/genSpace" -a 450
					fi

					mv evo.config.backup ../util/evo.config
					cat evosuite-report/statistics.csv >> $result_dir"/suites/"$project"_"$fault"/"$budget"/generation-statistics.csv"
					rm -rf evosuite-report

                                        # Detect and remove non-compiling tests
					echo "-----Checking to see if suite needs fixed"
					perl ../util/fix_test_suite_both.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -t $working_dir"/genSpace"

                                        # Generate coverage reports
                                        echo "-----Generating coverage reports"

					if [ $all_classes -eq 1 ]; then
						echo "(all loaded classes)"
	                                        perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -f "**/*Test.java" -t $working_dir"/genSpace" -c default -A

						perl ../bin/run_coverage_both.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -f "**/*Test.java" -t $working_dir"/genSpace" -A
					else
						echo "(only patched classes"
   					        perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -f "**/*Test.java" -t $working_dir"/genSpace" -c default

						perl ../bin/run_coverage_both.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -f "**/*Test.java" -t $working_dir"/genSpace"
					fi

					# Check fault coverage
					echo "-----Checking fault coverage"
					./measure_fault_coverage.sh $project $fault $trial "evosuite-"$criterion $budget $project_dir $result_dir

					# Measure fault detection
					echo "----Measuring fault detection"
				        perl ../bin/run_bug_detection.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$criterion -f "**/*Test.java" -t $working_dir"/genSpace" 	
					rm -rf $working_dir"/genSpace/"
				done
			done
		done
	done
done
