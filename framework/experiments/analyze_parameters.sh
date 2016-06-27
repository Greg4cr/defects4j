#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Perform analysis of parameter tuning results

parameters="9 10 11 12 14"

for parameter in $parameters; do
	echo `cat ptuning.csv | cut -d, -f $parameter | head -1`

	# To calculate: median/spread of fitness score, median/spread of convergence round
	values=`cat ptuning.csv | cut -d, -f $parameter | sort -n | uniq | tail -n +2`
	for val in $values; do
		cat ptuning.csv | awk -v P=$parameter -v V=$val '
			BEGIN{
				fitness[0]=0;
				convergence[0]=0;
			}
			{
				split($0,parts,",");
				if(parts[P] == V){
					fitness[++fitness[0]]=parts[3];
					convergence[++convergence[0]]=parts[2];
				}
			}
			END{
				# Sort entries
				total=fitness[0];
				asort(fitness);
				asort(convergence);
				
				if(total %2){
					midPoint = (total+1)/2;
					lowPoint = (total-midPoint)/2;
					upPoint = midPoint + lowPoint;

					medFit=fitness[midPoint];
					spreadFit = fitness[upPoint] - fitness[lowPoint];
	   				spreadConvergence = convergence[upPoint] - convergence[lowPoint];					
					medConvergence=convergence[midPoint];
				}else{
					midPoint = (total)/2;
					lowPoint = (total-midPoint)/2;
					upPoint = midPoint + lowPoint;

					medFit=((fitness[total/2] + fitness[(total/2)+1])/2.0);
					spreadFit = fitness[upPoint] - fitness[lowPoint];				
					medConvergence=((convergence[total/2] + convergence[(total/2)+1])/2.0);
					spreadConvergence = convergence[upPoint] - convergence[lowPoint];					
				}

				print V "," medFit "," spreadFit "," medConvergence "," spreadConvergence;
			}	
		'
	done
done

total=`cat ptuning.csv | wc -l`
total=$(($total-1))

echo "By Configuration:"
for (( end=10 ; end<=$total ; end=$(($end+10)) )); do
	cat ptuning.csv | head -n $end | tail -n 10 | awk '
			BEGIN{
				fitness[0]=0;
				convergence[0]=0;
			}
			{
				split($0,parts,",");
                                config=parts[8] "," parts[9] "," parts[10] "," parts[11] "," parts[12] "," parts[13] "," parts[14]
				fitness[++fitness[0]]=parts[3];
				convergence[++convergence[0]]=parts[2];
			}
			END{
				# Sort entries
				total=fitness[0];
				asort(fitness);
				asort(convergence);
				
				if(total %2){
					midPoint = (total+1)/2;
					lowPoint = (total-midPoint)/2;
					upPoint = midPoint + lowPoint;

					medFit=fitness[midPoint];
					spreadFit = fitness[upPoint] - fitness[lowPoint];
	   				spreadConvergence = convergence[upPoint] - convergence[lowPoint];					
					medConvergence=convergence[midPoint];
				}else{
					midPoint = (total)/2;
					lowPoint = (total-midPoint)/2;
					upPoint = midPoint + lowPoint;

					medFit=((fitness[total/2] + fitness[(total/2)+1])/2.0);
					spreadFit = fitness[upPoint] - fitness[lowPoint];				
					medConvergence=((convergence[total/2] + convergence[(total/2)+1])/2.0);
					spreadConvergence = convergence[upPoint] - convergence[lowPoint];					
				}

				print config "," medFit "," spreadFit "," medConvergence "," spreadConvergence;
			}	
		'

done
