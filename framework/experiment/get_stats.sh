# $1 = Projects
projects=$1

echo "Project,Fault,Budget,Criterion,Trial,Test Results,Branches Covered,Branches Total,BC,Size,Length,NumRemoved"
for project in $projects; do
	faults=`ls results/suites | grep $project`
	for fault in $faults; do
		faultNum=`echo $fault | cut -d'_' -f 2`
		budgets=`ls results/suites/$fault`
		for budget in $budgets; do
			criteria=`ls results/suites/$fault/$budget/logs | cut -d. -f 3 | sort | uniq | grep -v "log"`
			for criterion in $criteria; do
				logs=`ls results/suites/$fault/$budget/logs | grep $criterion`
				for log in $logs; do
					trial=`echo $log | cut -d. -f 4`
					crinosc=`echo $criterion | sed 's/:/-/g'`
					detected=`cat "results/suites/"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/bug_detection" | grep ","$trial"," | cut -d, -f 5`

					stats=`cat results/suites/$fault/$budget/logs/$log | awk '
						BEGIN{
							goals=-1;
							covered=-1;
							size=0;
							len=0;
							bFound=0;
						}
						/Coverage of criterion/ {
							if($0 ~ /BRANCH/){
								bFound = 1;
							}else{
								bFound = 0;
							}
						}
						/Total number of goals/ {
							if(bFound == 1){
								split($0,parts," ");
								if(goals==-1){
									goals=0;
								}
								goals=goals+parts[6];
							}
						}
						/Number of covered goals/ {
							if(bFound == 1){
								split($0,parts," ");
								if(covered==-1){
									covered=0;
								}
								covered=covered+parts[6];
							}
						}
						/tests with total length/ {
							split($0,parts," ");
							size=size+parts[3];
							len=len+parts[8];
						}	
						END{
							if(goals==-1){
								cov=-1;
							}else if(goals==0){
								cov=0;
							}else{
								cov=covered/goals;
							}
							print covered "," goals "," cov "," size "," len;
						}
					'`
					echo $project","$faultNum","$budget","$criterion","$trial","$detected","$stats","
				done
			done
		
		done		
	done
done

