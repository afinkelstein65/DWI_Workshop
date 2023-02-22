#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --mem=64gb
#SBATCH -p gpu --gres=gpu:1
#SBATCH --job-name="Preproc"
#SBATCH --mail-user=alan_finkelstein@urmc.rochester.edu
#SBATCH --mail-type=END

: '
DWI Multishell Tractography + Connectome Pipeline Processing
Script to preprocess T1 data and submit to freesurfer for cortical and subcortical parcellation.
Preprocess multishell DWI data
Preprocess T1 data

CSD and Tractrography performed using ...

Part of Microstructure Informed Tractography Project - Using T1, T2, and Fractional Volume Maps to
improve tractography.

Author: Alan Finkelstein
Date: 9/29/22
'

usage="\n$(basename $0) [-h] [-s] [-t] [-d]\n\n

--Performs Preprocessing of T1 data and Diffusion data for microstructural informed tractography. Be sure to include full file paths.\n\n

1. Register T1w data to Diffusion space (BO image).\n
2. Perform tissue segmentation and bias field correction using FSL FAST\n
3. Perform freesurfer parcellation on T1w data.\n

\nwhere:\n
  \n-h shows this help text
  \n-s subject directory with T1w and DWI data
  \n-t NIFTI corresponding the T1w data
  \n-d NIFTI corresponding to DWI data\n
"

dir1="/scratch/afinkel2/MRF_CI"
cd $dir1

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

DWI_ROOT=$(echo $DWI | cut -d "/" -f 9)
echo $DWI_ROOT
DWI_ROOT=$(echo $DWI_ROOT | cut -d "_" -f 1-2)
echo $DWI_ROOT
DWI_PA="${DWI_ROOT}_enc-pa_shl-0_dwi"
DWI_b1000="${DWI_ROOT}_enc-ap_shl-1000_dwi"
DWI_b2000="${DWI_ROOT}_enc-ap_shl-2000_dwi"

module load fsl
export FSLOUTPUTTYPE="NIFTI_GZ"
module load ants
module load freesurfer
module load mrtrix3/b2
source $FREESURFER_HOME/SetUpFreeSurfer.sh
# Useful commands - MRINFO

echo "Now preprocessing DWI Data"
# Preprocessing Mrtrix3
echo "Converting NIFTI data to MIF"

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
dwiextract "${ROOT}/${DWI_ROOT}_dwi.mif" - -bzero | mrmath - mean "${ROOT}/mean_b0_AP.mif" -axis 3 -force
mrmath "${ROOT}/${DWI_PA}.mif" -axis 3 "${ROOT}/mean_b0_PA.mif" -force
mrcat "${ROOT}/mean_b0_AP.mif" "${ROOT}/mean_b0_PA.mif" -axis 3 "${ROOT}/b0_pair.mif" -force

dwifslpreproc "${ROOT}/${DWI_ROOT}_dwi.mif" "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" -nocleanup -pe_dir AP -rpe_pair -se_epi "${ROOT}/b0_pair.mif" -force
#eddy options, slm = linear


# Create Brain Mask

# Register T1 to DWI b0

# Bias field correction using ANTS
#dwibiascorrect ants ...

# Creating Brain Mask
#dwi2mask ...

# T1 pre-processing
# Register T1 to Diffusion B0 corrected image.
# Perform Brain extraction
# Perform FAST for grey matter, white matter, CSF + Bias field + Bias field corrected image

# Submit bias field cocrrected image for freesurfer recon-all.

# submit

# Register to Diffusion Space

# DWI Pre-processing

#echo "Now Running FreeSurfer for ${subj}"

echo "Job Finished at" `date`
