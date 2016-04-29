#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate tests to find real faults in Mockito

trials=1
faults=1
criteria="default"
projects="Mockito"
result_dir="/tmp/mocketest"
budget=120
exp_dir=`pwd`

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
		
			# Generate EvoSuite tests
			for criterion in $criteria; do
				echo "-----Generating EvoSuite tests for "$criterion
				perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o "/tmp/"$project"_"$fault -c $criterion -b $budget
			done

			# Generate Randoop tests
			echo "-----Generating random tests"
			perl ../bin/run_randoop.pl -p $project -v $fault"f" -n $trial -o "/tmp/"$project"_"$fault -b $budget

			# Fault detection
			suites=`ls "/tmp/"$project"_"$fault"/"$project"/"`
			mkdir /tmp/tempResults
			for suite in $suites; do
				echo $suite
				echo "-----Checking to see if suite needs fixed: "$suite
				
				continue=1
				while [ "$continue" -gt "0" ]; do
					# Run fault detection for each suite to see if it needs fixed
					perl ../bin/run_bug_detection.pl -p $project -d "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/" -o /tmp/tempResults/checkout -f "**/*Test.java" >> "/tmp/tempResults/log_"$suite
					error=`cat "/tmp/tempResults/log_"$suite | grep error | wc -l`
				
					#Do we need to fix it?
					if [ "$error" -gt "0" ]; then
						echo "-----Fixing suite: "$suite
						# Unpack the archive
						mkdir /tmp/tempResults/unpack
						if [ $suite == "randoop" ]; then
							mkdir /tmp/tempResults/unpack/randoop
							tar xvjf "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/tmp/tempResults/unpack/randoop"

							# Fix the tests		
							./generate_broken_log.sh "/tmp/tempResults/log_"$suite "/tmp/tempResults/unpack/randoop/" "/tmp/tempResults/to_fix_"$suite "/tmp/tempResults/imports_"$suite
							perl ../util/rm_broken_tests.pl "/tmp/tempResults/to_fix_"$suite "/tmp/tempResults/unpack/randoop/"
							if [ -a "/tmp/tempResults/imports_"$suite ]; then
								gawk -f fix_import_statements.awk -v dir="/tmp/tempResults/unpack/randoop/" -v logFile="/tmp/tempResults/imports_"$suite
							fi
		
							# Repack the archive and replace the original				
							cd /tmp/tempResults/unpack/randoop
							tar cvjf $project"-"$fault"f-"$suite"."$trial".tar.bz2" "." 
							mv "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2.bak"
							mv $project"-"$fault"f-"$suite"."$trial".tar.bz2" "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" 
						else
							tar xvjf "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/tmp/tempResults/unpack"
						
							# Fix the tests		
							./generate_broken_log.sh "/tmp/tempResults/log_"$suite "/tmp/tempResults/unpack/" "/tmp/tempResults/to_fix_"$suite "/tmp/tempResults/imports_"$suite
							perl ../util/rm_broken_tests.pl "/tmp/tempResults/to_fix_"$suite "/tmp/tempResults/unpack/"
					
							if [ -a "/tmp/tempResults/imports_"$suite ]; then
								gawk -f fix_import_statements.awk -v dir="/tmp/tempResults/unpack/" -v logFile="/tmp/tempResults/imports_"$suite
							fi
										
							# Repack the archive and replace the original				
							cd /tmp/tempResults/unpack
							tar cvjf $project"-"$fault"f-"$suite"."$trial".tar.bz2" "org/" 
							mv "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2.bak"
							mv $project"-"$fault"f-"$suite"."$trial".tar.bz2" "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" 
						fi;
						cd $exp_dir
						rm -rf /tmp/tempResults/checkout
						rm "/tmp/tempResults/log_"$suite
						rm "/tmp/tempResults/to_fix_"$suite
						rm "/tmp/tempResults/imports_"$suite
					else
						let "continue = 0"
					fi
					echo $continue
				done

				# Run final fault finding
				perl ../bin/run_bug_detection.pl -p $project -d "/tmp/"$project"_"$fault"/"$project"/"$suite"/"$trial"/" -o $result_dir -f "**/*Test.java"
			done
		#	rm -rf /tmp/tempResults
			
		done
	done
done
