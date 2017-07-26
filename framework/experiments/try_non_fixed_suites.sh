#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Restore non-"fixed" suites and run FF using them
# Corrects a potential experimental issue preventing fault detection

projects=$1
budgets="120 600"
metrics="branch cbranch default exception line method methodnoexception output weakmutation"
d4j="/home/greg/svn/defects4j/framework"
working_dir="/tmp/"

for project in $projects; do
	faults=`ls $project | grep -v archive`

	for fault in $faults; do
		faultNum=`echo $fault | cut -d_ -f 2`
		for budget in $budgets; do
			for metric in $metrics; do
				rm $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/bug_detection"
				trials=`ls $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric | grep -v "bug_detection"`

				for trial in $trials; do
					echo "-----"$project","$faultNum","$budget","$metric","$trial
					if [ -a $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2.bak" ]; then
						# Archive 
						if [ -a $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2_fixed_both" ]; then
							"Not archiving"
						else
							mv $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2" $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2_fixed_both"
						fi

						# Fix for generation source only
	 					cp $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2.bak" $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial"/"$project"-"$faultNum"f-evosuite-"$metric"."$trial".tar.bz2"
						perl $d4j/util/fix_test_suite.pl -p $project -d $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial -t $working_dir"/"$project"_"$faultNum
					fi
					# Execute fault-finding
					perl $d4j/bin/run_bug_detection.pl -p $project -d $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric"/"$trial -o $project"/"$fault"/"$budget"/"$project"/evosuite-"$metric -f "**/*Test.java" -t $working_dir"/"$project"_"$faultNum

					rm -rf $working_dir"/"$project"_"$faultNum
				done
			done
		done
	done
done
