#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --mem=64gb
#SBATCH --job-name="Preproc"
#SBATCH --mail-user=your_email@urmc.rochester.edu
#SBATCH --mail-type=END

: '

Sample Script for DWI Processing for one subject. 

This script is just an example and will need to be modified based on your data organization and naming conventions.
It is best to follow the BIDS data format - https://bids.neuroimaging.io/. 

More resources about submitting jobs and slurm can be found here: https://info.circ.rochester.edu/#BlueHive/Getting_Started/index.html 
Go to Bluehive > Running Jobs > SLURM
You will need to be logged on to UR_MCwireless or UR_Connected to access. 


This script predominately uses mrtrix3. Similar scripts can be written using FSL or dipy depending on your preference. 

Author: Alan Finkelstein
Email: alan_finkelstein@urmc.rochester.edu
Date: January 2023
'

usage="\n$(basename $0) [-h] [-s] [-t] [-d]\n

where:\n
	\t-h: shows this help text\n
	\t-s: is the subject directory with t1w and DWI data\n
	\t-t: NIFTI corresponding to the T1w data
	\t-d: NIFTI corresponding to DWI data\n
"


while getopts "hs:t:d:" flag; do 
	case "${flag}" in
		h) echo -e $usage
		    exit 0 ;;
		  s) ROOT=${OPTARG};;
		  t) T1W=${OPTARG};;
		  d) DWI=${OPTARG};;
		  *)
		      echo -e $usage
		      exit 1;;
	esac
done

# This is for multishell data with b1000 and b2000
# can use mrinfo <file> to get information about data such as resolution, voxel size, number of directions, etc. 

DWI_ROOT=$(echo $DWI | cut -d "/" -f 9)
DWI_ROOT=$(echo $DWI_ROOT | cut -d "_" -f 1-2)
DWI_PA="${DWI_ROOT}_enc-pa_shl-0_dwi"
DWI_b1000="${DWI_ROOT}_enc-ap_shl-1000_dwi"
DWI_b2000="${DWI_ROOT}_enc-ap_shl-2000_dwi"

# Load all modules that will be used or need to be used by other programs. 
module load fsl
export FSLOUTPUTTYPE="NIFTI_GZ"
module load ants
module load freesurfer
module load mrtrix3/b2
source $FREESURFER_HOME/SetUpFreeSurfer.sh

echo "Now preprocessing DWI Data"
# Preprocessing Mrtrix3
echo "Converting NIFTI data to MIF"

# convert nifti data to mif  (mrtrix imaging format)
mrconvert "${ROOT}/${DWI_b1000}.nii.gz" -fslgrad "${ROOT}/${DWI_b1000}.bvec" "${ROOT}/${DWI_b1000}.bval" "${ROOT}/${DWI_b1000}.mif" -force
mrconvert "${ROOT}/${DWI_b2000}.nii.gz" -fslgrad "${ROOT}/${DWI_b2000}.bvec" "${ROOT}/${DWI_b2000}.bval" "${ROOT}/${DWI_b2000}.mif" -force
mrconvert "${ROOT}/${DWI_PA}.nii.gz" "${ROOT}/${DWI_PA}.mif" -force
mrconvert "${ROOT}/${DWI_ROOT}_T1w.nii.gz" "${ROOT}/${DWI_ROOT}_T1.mif" -force

# Denoise using MP-PCA
dwidenoise "${ROOT}/${DWI_b1000}.mif" "${ROOT}/${DWI_ROOT}_denoised1000.mif" -force
dwidenoise "${ROOT}/${DWI_b2000}.mif" "${ROOT}/${DWI_ROOT}_denoised2000.mif" -force

# get residual
module unload mrtrix3/b2
module load mrtrix3/b3


mrcalc "${ROOT}/${DWI_b1000}.mif" "${ROOT}/${DWI_ROOT}_denoised1000.mif" -subtract "${ROOT}/residual1000.mif" -force
mrcalc "${ROOT}/${DWI_b2000}.mif" "${ROOT}/${DWI_ROOT}_denoised2000.mif" -subtract "${ROOT}/residual2000.mif" -force

# combine multi-shell data
dwicat "${ROOT}/${DWI_ROOT}_denoised1000.mif" "${ROOT}/${DWI_ROOT}_denoised2000.mif" "${ROOT}/${DWI_ROOT}_dwi.mif"

echo "Now preprocessing DWI data - Distortion Correction + Eddy Correction"
# get bzero data (AP)
dwiextract "${ROOT}/${DWI_ROOT}_dwi.mif" - -bzero | mrmath - mean "${ROOT}/mean_b0_AP.mif" -axis 3 -force
# get PA bzero
mrmath "${ROOT}/${DWI_PA}.mif" -axis 3 "${ROOT}/mean_b0_PA.mif" -force

#concat AP and PA
mrcat "${ROOT}/mean_b0_AP.mif" "${ROOT}/mean_b0_PA.mif" -axis 3 "${ROOT}/b0_pair.mif" -force

# Preprocess data - eddy correct and susceptibility correction. 
dwifslpreproc "${ROOT}/${DWI_ROOT}_dwi.mif" "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" -nocleanup -pe_dir AP -rpe_pair -se_epi "${ROOT}/b0_pair.mif" -force
#eddy options, slm = linear

echo "Job Finished at" `date`