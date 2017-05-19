# Gregory Gay (greg@greggay.com)
# Fixes import statements in noncompiling test classes
# Pass in parameters:
# dir = directory where tests are stored
# logFile = log in format "class, import statement to fix"

BEGIN{
	OFS=FS=",";
	files[0]=0;
	imports[0]=0;
	while(getline x < logFile){
		split(x,parts,",");
		files[++files[0]]=parts[1];
		imports[++imports[0]]=parts[2];
	}
	close(logFile);

	for(file=1;file<=files[0];file++){
		# Make a backup of the file
		system("cp "dir"/"files[file]".java "dir"/"files[file]".java.bak2");
		toRead=dir"/"files[file]".java";
		tmpOut=dir"/tmp.java";
		while(getline x < toRead){
			if(x ~ import){
				if(x !~ imports[file]){
					print x > tmpOut;
				}else{
					print "// "x > tmpOut;
				}
			}else{
				print x > tmpOut;
			}
		}
		close(toRead);
		close(tmpOut);	
		system("mv "tmpOut" "toRead);
	}
}
