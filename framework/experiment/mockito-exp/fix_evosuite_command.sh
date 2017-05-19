#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Fix the evosuite <evosuite> bug, part of fix_evosuite_bug.sh

cat $1 | gawk '
{ 
	if($0 ~ /<evosuite>/){
		print "// "$0;
	}else{
		print $0;
	}
}' >> tmp.java
mv tmp.java $1
