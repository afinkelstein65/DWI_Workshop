#!/bin/bash

#SBATCH -t 5-00:00:00 --mem=16GB


usage="$(basename $0) [-r] [-h] [-t] [-l] [-m] [-n] [-o]"

while getopts "hr:t:l:m:n:o:" flag; do
	case "${flag}" in 
		h) echo -e $usage
		exit 0 ;; 
		r) ROOT=${OPTARG};;
		t) TRACT=${OPTARG};;
		l) LABEL=${OPTARG};;
		n) OUTLABEL=${OPTARG};; 
		m) MAXLABEL=${OPTARG};;
		o) OUTDIR=${OPTARG};; 
		*) echo "Usage cmd [-r] [-t] [-l] [-m] [-o]"
		exit 0 ;; 
	esac 
done

module load anaconda3
module load scilpy 

# cd $ROOT

TRACT2=$(echo ${TRACT} | cut -d "." -f 1)

echo $TRACT2


python ConnectivityPrepare.py "${LABEL}" "${OUTLABEL}"

scil_convert_tractogram.py "${TRACT}" "${TRACT2}.trk" --reference "${OUTLABEL}" -f

scil_compute_connectivity.py "${TRACT2}.trk" $OUTLABEL $MAXLABEL $OUTDIR -f -v
