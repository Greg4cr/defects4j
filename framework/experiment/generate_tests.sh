#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generate tests to find real faults in Mockito

trials=30
faults=17
criteria="default" 
#branch line output weakmutation exception method methodnoexception"
projects="Mockito"
result_dir="working/mocketest"
budget=600
exp_dir=`pwd`

mkdir $result_dir
echo "Project,Fault Number,Trial,Test Source,Total Number of Tests,Number of Tests Removed" >> $result_dir"/test_stats.csv"

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for (( fault=17 ; fault <= $faults ; fault++ )); do
		echo "-----Fault #"$fault
		# For each trial
		for (( trial=15; trial <= $trials ; trial++ )); do
			echo "-----Trial #"$trial
		
			# Generate EvoSuite tests
			for criterion in $criteria; do
				mkdir /media/greg/WorkDrive2/tmp/genSpace/
				echo "-----Generating EvoSuite tests for "$criterion
				perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o "working/suites/"$project"_"$fault -c $criterion -b $budget -t /media/greg/WorkDrive2/tmp/genSpace/
				rm -rf /media/greg/WorkDrive2/tmp/genSpace/
			done

			# Generate Randoop tests
			echo "-----Generating random tests"
			mkdir /media/greg/WorkDrive2/tmp/genSpace/
			perl ../bin/run_randoop.pl -p $project -v $fault"f" -n $trial -o "working/suites/"$project"_"$fault -b 120 -t /media/greg/WorkDrive2/tmp/genSpace/
			rm -rf /media/greg/WorkDrive2/tmp/genSpace/

			# Fault detection
			suites=`ls "working/suites/"$project"_"$fault"/"$project"/"`
			mkdir /media/greg/WorkDrive2/tmp/tempResults
			for suite in $suites; do
				{
				echo $suite
				echo "-----Checking to see if suite needs fixed: "$suite
				
				continue=1
				numTestsRemoved=0
				fixed=0
				while [ "$continue" -gt "0" ]; do
					# Run fault detection for each suite to see if it needs fixed
					perl ../bin/run_bug_detection.pl -p $project -d "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/" -o /media/greg/WorkDrive2/tmp/tempResults/checkout -f "**/*Test.java" >> "/media/greg/WorkDrive2/tmp/tempResults/log_"$suite
					error=`cat "/media/greg/WorkDrive2/tmp/tempResults/log_"$suite | grep error | wc -l`
				
					#Do we need to fix it?
					mkdir /media/greg/WorkDrive2/tmp/tempResults/unpack
					if [ "$error" -gt "0" ]; then
						echo "-----Fixing suite: "$suite
						# Unpack the archive
						if [ $suite == "randoop" ]; then
							mkdir /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop
							tar xvjf "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/media/greg/WorkDrive2/tmp/tempResults/unpack/randoop"
							if [ "$fixed" -eq "0" ]; then
								numTests=`grep -IR @Test /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/ | grep -v ".bak" | wc -l`
								echo "Num Tests "$numTests
								let "fixed = 1"
							fi

							# Fix the tests		
							./generate_broken_log.sh "/media/greg/WorkDrive2/tmp/tempResults/log_"$suite "/media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/" "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite "/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite
							newRemoved=`cat "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite | grep "::" | uniq | wc -l`
							let "numTestsRemoved= $numTestsRemoved + $newRemoved"
							echo $newRemoved" tests removed, "$numTestsRemoved" to date, out of "$numTests" tests."
							perl ../util/rm_broken_tests.pl "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite "/media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/"
							if [ -a "/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite ]; then
								gawk -f fix_import_statements.awk -v dir="/media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/" -v logFile="/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite
							fi
		
							# Repack the archive and replace the original				
							cd /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop
							tar cvjf $project"-"$fault"f-"$suite"."$trial".tar.bz2" "." 
							mv $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2.bak"
							mv $project"-"$fault"f-"$suite"."$trial".tar.bz2" $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" 
						else
							tar xvjf "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/media/greg/WorkDrive2/tmp/tempResults/unpack"
							if [ "$fixed" -eq "0" ]; then
								numTests=`grep -IR @Test /media/greg/WorkDrive2/tmp/tempResults/unpack/ | grep -v ".bak" | wc -l`
								echo "Num Tests "$numTests
								let "fixed = 1"
							fi
							# Fix the tests		
							./generate_broken_log.sh "/media/greg/WorkDrive2/tmp/tempResults/log_"$suite "/media/greg/WorkDrive2/tmp/tempResults/unpack/" "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite "/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite
							newRemoved=`cat "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite | grep "::" | uniq | wc -l`
							let "numTestsRemoved= $numTestsRemoved + $newRemoved"
							echo $newRemoved" tests removed, "$numTestsRemoved" to date, out of "$numTests" tests."
							perl ../util/rm_broken_tests.pl "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite "/media/greg/WorkDrive2/tmp/tempResults/unpack/"
					
							if [ -a "/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite ]; then
								gawk -f fix_import_statements.awk -v dir="/media/greg/WorkDrive2/tmp/tempResults/unpack/" -v logFile="/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite
							fi
										
							# Repack the archive and replace the original				
							cd /media/greg/WorkDrive2/tmp/tempResults/unpack
							tar cvjf $project"-"$fault"f-"$suite"."$trial".tar.bz2" "org/" 
							mv $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2.bak"
							mv $project"-"$fault"f-"$suite"."$trial".tar.bz2" $exp_dir"/working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" 
						fi;
						cd $exp_dir
						rm -rf /media/greg/WorkDrive2/tmp/tempResults/checkout
						rm -rf /media/greg/WorkDrive2/tmp/tempResults/unpack
						rm "/media/greg/WorkDrive2/tmp/tempResults/log_"$suite
						rm "/media/greg/WorkDrive2/tmp/tempResults/to_fix_"$suite
						rm "/media/greg/WorkDrive2/tmp/tempResults/imports_"$suite
					else
						let "continue = 0"

						#Get number of tests if no tests were fixed.
						if [ "$fixed" -eq "0" ]; then
							if [ $suite == "randoop" ]; then
								mkdir /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop
								tar xvjf "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/media/greg/WorkDrive2/tmp/tempResults/unpack/randoop"
								numTests=`grep -IR @Test /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/ | grep -v ".bak" | wc -l`
								echo "Num Tests "$numTests
								rm -rf /media/greg/WorkDrive2/tmp/tempResults/unpack/randoop/
							else
								tar xvjf "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/"$project"-"$fault"f-"$suite"."$trial".tar.bz2" -C "/media/greg/WorkDrive2/tmp/tempResults/unpack"
								numTests=`grep -IR @Test /media/greg/WorkDrive2/tmp/tempResults/unpack/ | grep -v ".bak" | wc -l`
								echo "Num Tests "$numTests
								rm -rf /media/greg/WorkDrive2/tmp/tempResults/unpack/*
							fi
						fi
					fi
					echo $continue
				done
				echo $project","$fault","$trial","$suite","$numTests","$numTestsRemoved >> $result_dir"/test_stats.csv"

				# Run final fault finding and coverage
				#mkdir /media/greg/WorkDrive2/tmp/genSpace/
				#perl ../bin/run_bug_detection.pl -p $project -d "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/" -o $result_dir -f "**/*Test.java" -t /media/greg/WorkDrive2/tmp/genSpace
				#perl ../bin/run_coverage.pl -p $project -d "working/suites/"$project"_"$fault"/"$project"/"$suite"/"$trial"/" -o $result_dir -f "**/*Test.java" -t /media/greg/WorkDrive2/tmp/genSpace
				#rm -rf /media/greg/WorkDrive2/tmp/genSpace/
			}
			done
			rm -rf /media/greg/WorkDrive2/tmp/tempResults
		done
	done
done
