#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Try a variety of settings for OptiSuite for a fixed target and select the best parameters

ops="OP UC DR"
pops="100 200 300 400 500 600 700 800 900 1000"
budgets="100 200 300 400 500 600 700 800 900 1000"
stags="50 100 150 200"
prs="0.2"
pms="0.2"
pxs="0.5"


for op in $ops; do
	for pop in $pops; do
		for budget in $budgets; do
			for stag in $stags; do
				if [ $stag -lt $budget ]; then
					for pr in $prs; do
						for pm in $pms; do
							for px in $pxs; do
								check=`awk -v PR=$pr -v PM=$pm -v PX=$px ' BEGIN{ sum=PR+PM+PX; if(sum > 1.0){ print "no"}else{ print sum;}}'`

                                	                        if [ "$check" != "no" ]; then
									python OptiSuite.py -m /tmp/suiteSpace/matrices/org.apache.commons.lang3.LocaleUtils.csv -n 10 -c max -s min -a $op -p $pop -b $budget -q $stag -r $pr -t $pm -x $px -z $RANDOM 2>&1 | tee -a "ptuning.csv" 
								fi
							done
						done
					done	
				fi
			done			
		done
	done
done


