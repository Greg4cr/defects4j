#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Try a variety of settings for OptiSuite for a fixed target and select the best parameters

ops="OP UC DR"
pops="50 100 150 200 250 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000"
budgets="50 100 150 200 250 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000"
stags="10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200"
prs="0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
pms="0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
pxs="0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"


for op in $ops; do
	for pop in $pops; do
		for budget in $budgets; do
			for stag in $stags; do
				for pr in $prs; do
					for pm in $pms; do
						for px in $pxs; do
							check=`awk -v PR=$pr -v PM=$pm -v PX=$px ' BEGIN{ sum=PR+PM+PX; if(sum > 1.0){ print "no"}else{ print sum;}}'`

                                                        if [ "$check" != "no" ]; then
								python OptiSuite.py -m /tmp/suiteSpace/matrices/org.apache.commons.lang3.LocaleUtils.csv -n 10 -c max -s min -a $op -p $pop -b $budget -q $stag -r $pr -t $pm -x $px -z $RANDOM 2>&1 | tee "ptuning.csv" 
							fi
						done
					done
				done	
			done			
		done
	done
done


