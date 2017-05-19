# WIP - Make it easier to identify false positives in Randoop results by comparing stack trace. 
# Redesign later - this approach isn't great - just a quick hack

BEGIN{
	# Get list of trigger tests and causes
	cause[0]=0;
	stack[0,0]=0;
	while(getline x < Trigger){
		if(x ~ "--- "){
			cause[0]++;
			stack[cause[0],0]=0;
		}else if((x ~ /Exception/) || (x ~ /AssertionFailedError/)){
			cause[cause[0]]=x;
		}else{
			stack[cause[0],++stack[cause[0],0]]=x;
		}
	}
	close(Trigger);

	# Get list of tests that fail in isolation.
	isolated[0]=0
	while(getline x < TestList){
		isolated[++isolated[0]]=x;
	}
	close(TestList);

	# Go through and filter tests
	# Found = test number in isolated
	testName="";
	while(getline x < Traces){
		if(x ~ "--- "){
			if(found > 0){
				print "Common trace elements :"common;
			}
			found=0;
			for(test=1;test<=isolated[0];test++){
				if(x == isolated[test]){
					found=test;
					break;
				}
			}
			testName=x;
			common=0;
		}else if((x ~ /AssertionFailedError/) && (found >0)){
			# Is the assertion similar?			
			print testName;
			print x;
		}else if(((x ~ /Exception/) || (x ~ /Error/)) && (found > 0)){
			# Does the exception match any in the triggers?
			for(test=1;test<=cause[0];test++){
				split(cause[0],tCause,":");
				split(x,gCause,":");
				if(tCause[1] == gCause[1]){
					print testName;
					print x;
				}else{
					found=0;
				}
			}
		}else if(((x ~ /\tat /) && ((x ~ /mockito/) || (x ~ /Mockito/))) && (found > 0)){
			# Does this line from the stack trace appear in any of the triggering tests?
			split(x,words," ");
			split(words[2],parts,"(");
			method=parts[1];
			for(test=1;test<=cause[0];test++){
				for(line=1;line<=stack[test,0];line++){
					split(stack[test,line],lwords," ");
					split(lwords[2],lparts,"(");
					lMethod=lparts[1];

					if(method==lMethod){
						common++;
						print "Trigger "test":"method;
					}
				}			
			}
		}else if((x !~ /\tat /) && (found > 0)){
			print x;
		}
	}
	close(Traces);


#	for(i=1;i<=cause[0];i++){
#		print cause[i];
#		for(j=1;j<=stack[i,0];j++){
#			print stack[i,j];
#		}
#	}
}
