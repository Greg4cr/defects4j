#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate tests to find real faults in Defects4J Programs

# Set at command line
projects=$1
faults=`cat $2 | sed 's/,/ /g'`
trials=$3
budgets=$4
criteria=`cat $5 | sed 's/,/ /g'`
project_dir=$6"/framework/projects"
all_classes=$7 #1 to generate tests for all loaded classes, 0 to only generate tests for patched classes

# Pre-configured
exp_dir=`pwd`
result_dir=$exp_dir"/results"
working_dir="/tmp"

mkdir $result_dir

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for fault in $faults; do
		echo "-----Fault #"$fault
		# For each trial
		for (( trial=1; trial <= $trials ; trial++ )); do
			echo "-----Trial #"$trial
			# For each search budget
			for budget in $budgets; do
				echo "----Search Budget: "$budget	
				# Generate EvoSuite tests
				for criterion in $criteria; do
					crinosc=`echo $criterion | sed 's/:/-/g'`
					mkdir $working_dir"/"$project"_"$fault

                                        if [ -a $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" ]; then
						echo "Suite already exists."
					else
						echo "-----Generating EvoSuite tests for "$criterion
						# Add configuration ID to evo config
						cp ../util/evo.config evo.config.backup
                       		        	echo "-Dconfiguration_id=evosuite-"$crinosc"-"$trial >> ../util/evo.config

						if [ $all_classes -eq 1 ]; then
							echo "(all loaded classes)"
							perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/"$project"_"$fault -a 450 -A
						else
							echo "(only patched classes)"
							perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/"$project"_"$fault -a 450 
						fi

						mv evo.config.backup ../util/evo.config
						cat evosuite-report/statistics.csv >> $result_dir"/suites/"$project"_"$fault"/"$budget"/generation-statistics.csv"
						rm -rf evosuite-report
					fi

                                	# Detect and remove non-compiling tests
					echo "-----Checking to see if suite needs fixed"
					perl ../util/fix_test_suite.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -t $working_dir"/"$project"_"$fault
					#continue=1
					#numTestsRemoved=0
					#fixed=0
					#while [ "$continue" -gt "0" ]; do
						# Run fault detection for each suite to see if it needs fixed
					#	mkdir /tmp/tmpResults
					#	perl ../bin/run_bug_detection.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc -f "**/*Test.java" -t $working_dir"/"$project"_"$fault >> "/tmp/tmpResults/log_"$project"_"$fault"_"$trial
					#	error=`cat "/tmp/tmpResults/log_"$project"_"$fault"_"$trial | grep error | wc -l`
				
						#Do we need to fix it?
					#	mkdir /tmp/tmpResults/unpack
					#	if [ "$error" -gt "0" ]; then
					#		bugDetection=`cat $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/bug_detection" | grep ","$trial"," | wc -l`
					#		if [ "$bugDetection" -eq "1" ]; then
					#			head -n -1 $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/bug_detection" >> tempFile
					#			mv tempFile $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/bug_detection"
					#		fi

					#		echo "-----Fixing suite"
							# Unpack the archive
					#		tar xvjf $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" -C "/tmp/tmpResults/unpack"
				#			if [ "$fixed" -eq "0" ]; then
				#				numTests=`grep -IR @Test /tmp/tmpResults/unpack/ | grep -v ".bak" | wc -l`
				#				echo "Num Tests "$numTests
				#				let "fixed = 1"
				#			fi
							# Fix the tests		
				#			./generate_broken_log.sh "/tmp/tmpResults/log_"$project"_"$fault"_"$trial "/tmp/tmpResults/unpack/" "/tmp/tmpResults/to_fix_"$project"_"$fault"_"$trial "/tmp/tmpResults/imports_"$project"_"$fault"_"$trial
				#			newRemoved=`cat "/tmp/tmpResults/to_fix_"$project"_"$fault"_"$trial | grep "::" | uniq | wc -l`
				#			let "numTestsRemoved= $numTestsRemoved + $newRemoved"
				#			echo $newRemoved" tests removed, "$numTestsRemoved" to date, out of "$numTests" tests."
				#			perl ../util/rm_broken_tests.pl "/tmp/tmpResults/to_fix_"$project"_"$fault"_"$trial "/tmp/tmpResults/unpack/"
					
				#			if [ -a "/tmp/tmpResults/imports_"$project"_"$fault"_"$trial ]; then
				#				gawk -f fix_import_statements.awk -v dir="/tmp/tmpResults/unpack/" -v logFile="/tmp/tmpResults/imports_"$project"_"$fault"_"$trial
				#			fi
										
							# Repack the archive and replace the original				
				#			exp_dir=`pwd`
				#			cd /tmp/tmpResults/unpack
				#			tar cvjf $project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" "org/" 
				#			mv $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2.bak"
				#			mv $project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" 
				#			cd $exp_dir
				#			rm -rf /tmp/tmpResults/checkout
				#			rm -rf /tmp/tmpResults/unpack
				#			rm "/tmp/tmpResults/log_"$project"_"$fault"_"$trial
				#			rm "/tmp/tmpResults/to_fix_"$project"_"$fault"_"$trial
				#			rm "/tmp/tmpResults/imports_"$project"_"$fault"_"$trial
				#		else
				#			let "continue = 0"
				#		fi
				#	echo $continue
				#	done

                        	                # Generate coverage reports
#                                	        echo "-----Generating coverage reports"

#						if [ $all_classes -eq 1 ]; then
#							echo "(all loaded classes)"
#	                                	        perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault -c default -A

#							perl ../bin/run_coverage_both.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault -A
#						else
#							echo "(only patched classes"
 #  						        perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault -c default

#							perl ../bin/run_coverage_both.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault
#						fi

						# Check fault coverage
#						echo "-----Checking fault coverage"
#						./measure_fault_coverage.sh $project $fault $trial "evosuite-"$crinosc $budget $project_dir $result_dir

						# Measure fault detection
					echo "----Measuring fault detection"
				    	perl ../bin/run_bug_detection.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc -f "**/*Test.java" -t $working_dir"/"$project"_"$fault
					#rm -rf $working_dir"/"$project"_"$fault 
				done
			done
		done
		# Back up to cloud
		tar cvzf $project"_"$fault"_"$budgets".tgz" $result_dir"/suites/"$project"_"$fault"/"
	#	scp $project"_"$fault"_"$budgets"_custom.tgz" bstech@blankslatetech.com:/home/bstech/greggay.com/data/	
	done
done
