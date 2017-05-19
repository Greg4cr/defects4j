#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Generates a CSV of tests that pass on fixed version and fail on faulty and a list of those tests for inspection.

# $1 = result directory

project="Mockito"
suites="evosuite-default randoop"
faults=17

mkdir $1"/isolated_tests"

echo "Project,Test Source,Fault,Trial,Isolated Kills"
for suite in $suites; do
	mkdir $1"/isolated_tests/"$suite

	for (( fault=1 ; fault <= $faults ; fault++ )); do
		files=`ls $1"/bug_detection_log/"$project"/"$suite"/" | grep ".trigger.log" | grep $fault"f"`
		numFiles=`ls $1"/bug_detection_log/"$project"/"$suite"/" | grep ".trigger.log" | grep $fault"f" | wc -l`
		avgKilled=0

		for file in $files; do
			trial=`echo $file | cut -d"." -f 2`
			gawk -v Fixed=$1"/bug_detection_log/"$project"/"$suite"/"$file -v Faulty=$1"/bug_detection_log/"$project"/"$suite"/"$fault"b."$trial".trigger.log" '
				BEGIN{
					fixedTests[0]=0;
					faultyTests[0]=0;
					while(getline x < Fixed){
						if(x ~ "--- "){
							fixedTests[++fixedTests[0]]=x
						}
					}
					close(Fixed);

					while(getline x < Faulty){
						if(x ~ "--- "){
							faultyTests[++faultyTests[0]]=x
						}
					}
					close(Faulty);
					
					#Compare fixed and faulty
					for(test=1;test<=faultyTests[0];test++){
						found=0;
						for(compare=1;compare<=fixedTests[0];compare++){
							if(fixedTests[compare]==faultyTests[test]){
								found=1;
								break;
							}
						}
						if(found==0){
							print faultyTests[test];
						}	
					}
				}' >> $1"/isolated_tests/"$suite"/"$fault"b."$trial".log"
			killed=`cat $1"/isolated_tests/"$suite"/"$fault"b."$trial".log" | wc -l`

			echo $project","$suite","$fault","$trial","$killed

			avgKilled=$(($avgKilled+$killed))
		done

		if [ "$numFiles" -gt "0" ]; then
			avgKilled=`bc <<< 'scale=2; '$avgKilled'/'$numFiles`
			echo $project","$suite","$fault",Average,"$avgKilled
		fi
	done
done

