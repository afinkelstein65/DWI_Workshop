#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --mem=64gb
#SBATCH -p gpu --gres=gpu:1
#SBATCH --job-name="T1_Preproc"
#SBATCH --mail-user=alan_finkelstein@urmc.rochester.edu
#SBATCH --mail-type=END

: '
DWI Multishell Tractography + Connectome Pipeline Processing
Script to preprocess T1 data and submit to freesurfer for cortical and subcortical parcellation.
Preprocess T1 data

CSD and Tractrography performed using ...

Part of Microstructure Informed Tractography Project - Using T1, T2, and Fractional Volume Maps to
improve tractography.

Author: Alan Finkelstein
Date: 10/5/22
'

usage="\n$(basename $0) [-h] [-s] [-t] [-d]\n\n

--Performs Preprocessing of T1 data and Diffusion data for microstructural informed tractography. Be sure to include full file paths.\n\n

1. Register T1w data to Diffusion space (BO image).\n
3. Denoising and Gibbs Ringing\n
4. Perform freesurfer parcellation on T1w data.\n

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

module load fsl
export FSLOUTPUTTYPE="NIFTI_GZ"
module load ants
module load freesurfer
module load mrtrix3/b3
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR="${ROOT}"

# get mean bzero for preprocessed data
dwiextract "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" - -bzero | mrmath - mean "${ROOT}/mean_bzero.mif" -axis 3 -force

#Register T1 to Diffusion
#rregister "${ROOT}/${DWI_ROOT}_T1.mif" "${ROOT}/mean_bzero.mif" -type affine -transformed "${ROOT}/T1_coreg_diff.mif" -force

#Create DWI mask, apply to T1
dwi2mask "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" "${ROOT}/${DWI_ROOT}_BrainMask.mif" -force
maskfilter "${ROOT}/${DWI_ROOT}_BrainMask.mif" dilate -npass 2 "${ROOT}/${DWI_ROOT}_BrainMask_Dilated.mif"
mrcalc "${ROOT}/${DWI_ROOT}_dwi_preproc.mif"  "${ROOT}/${DWI_ROOT}_BrainMask_Dilated.mif" -multiply "${ROOT}/dwi_brain.mif"

mrconvert  "${ROOT}/${DWI_ROOT}_BrainMask_Dilated.mif"  "${ROOT}/${DWI_ROOT}_BrainMask.nii.gz" -force
mrconvert "${ROOT}/mean_bzero.mif" "${ROOT}/mean_bzero.nii.gz" -force
flirt -in "${ROOT}/${DWI_ROOT}_T1w.nii.gz" -ref "${ROOT}/mean_bzero.nii.gz" -out "${ROOT}/T1_coreg_diff.nii.gz"
fslmaths "${ROOT}/T1_coreg_diff.nii.gz" -mul "${ROOT}/${DWI_ROOT}_BrainMask.nii.gz" "${ROOT}/T1_coreg_diffbrain.nii.gz"

# perform FAST for tissue segmentation and bias field correction.
fast -B -b "${ROOT}/T1_coreg_diffbrain.nii.gz"
fslmaths "${ROOT}/T1_coreg_diffbrain_pve_0.nii.gz" -bin "${ROOT}/CSF_mask.nii.gz"
fslmaths "${ROOT}/T1_coreg_diffbrain_pve_1.nii.gz" -bin "${ROOT}/GM_mask.nii.gz"
fslmaths "${ROOT}/T1_coreg_diffbrain_pve_2.nii.gz" -bin "${ROOT}/WM_mask.nii.gz"


# run freesurfer
recon-all -all -s "${ROOT}/${DWI_ROOT}_freesurfer" -i "${ROOT}/T1_coreg_diffbrain_restore.nii.gz"
