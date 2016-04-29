#!/bin/bash
# Gregory Gay <greg@greggay.com>
# Parse output of compilation and generate a list of broken classes
# $1 = output of compilation
# $2 = directory where original test files are kept 
# $3 = where to output log file
# $4 = where to output imports file

cat $1 | gawk -v testDir=$2 -v logFile=$3 -v importFile=$4 'BEGIN{
		files[0]=0;
		lines[0]=0;
		classes[0]=0;	
		#failingClasses[0]=0;	
		grabImport=0
	}
	/: error:/ {
		# Parse error messages to get filenames and line numbers
		split($0,parts,":");
		split(parts[1],fileNameParts,"]");
		if(fileNameParts[2] ~ "randoop"){
			split(fileNameParts[2],fNameParts,"randoop/");
			files[++files[0]]=testDir"/"fNameParts[2];
			class=substr(fNameParts[2],0,index(fNameParts[2],".")-1);
			classes[++classes[0]]=class;
		}else if(fileNameParts[2] ~ "evosuite"){
			split(fileNameParts[2],fNameParts,"evosuite");
			intermediate=substr(fNameParts[2],index(fNameParts[2],"/")+1);
			files[++files[0]]=testDir"/"intermediate;
			class=substr(intermediate,0,index(intermediate,".")-1);

			classes[++classes[0]]=class;
		}
		lines[++lines[0]]=parts[2];
		
		grabImport=1;
	}
	/import / {
		if(grabImport==1){
			out=classes[classes[0]]",";
			split($0,parts,"import ");
			print out parts[2] > importFile;
		}
	}
	/: warning:/ { grabImport=0;}
	END{
		# Find the broken test method
		for(f=1; f<=files[0]; f++){
			gsub(/ /,"",files[f]);
			lNum=0;
			method="";
			newTest=0;
			while(getline x < files[f]){
				lNum++;
				if(lNum >= lines[f]){
					break;
				}else{
					#Which test are we looking at?
					if(x ~ "@Test"){
						newTest=1;
					}else if(newTest==1){
						newTest=0;
						split(x,parts,"(");
						split(parts[1],moreParts,"void");
						method=substr(moreParts[2],2);
					}
				}	
			}	
			close(files[f]);
			gsub(/\//,".",classes[f]);
			if(method==""){
				#broken=0;
				#for(c=1;c<=failingClasses[0];c++){
				#	if(failingClasses[c]==classes[f]){
				#		broken=1;
				#		break;
				#	}
				#}
				#if(broken==0){
					print "--- "classes[f] > logFile;
				#	failingClasses[++failingClasses[0]]=classes[f];
				#}
			}else{
				#broken=0;
				#for(c=1;c<=failingClasses[0];c++){
				#	if(failingClasses[c]==classes[f]){
				#		broken=1;
				#		break;
				#	}
				#}
				#if(broken==0){
					print "--- "classes[f]"::"method > logFile;
				#}
			}
		}
	}' 
