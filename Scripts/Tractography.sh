#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=64gb
#SBATCH -p gpu --gres=gpu:1
#SBATCH --job-name="Tractography"
#SBATCH --mail-user=alan_finkelstein@urmc.rochester.edu
#SBATCH --mail-type=END
#SBATCH --output="OutFiles/Tractography.out"

: '
DWI Multishell Tractography + Connectome Pipeline Processing
Script to preprocess T1 data and submit to freesurfer for cortical and subcortical parcellation.
Preprocess T1 data

CSD and Tractrography performed using .

Part of Microstructure Informed Tractography Project - Using T1, T2, and Fractional Volume Maps to
improve tractography.

Author: Alan Finkelstein
Date: 10/5/22

Notes:

First need to generate basis functions (response function) for WM, GM, and CSF. Have an idea of what the data should
look like for each tissue type.

need multiple b-values for MSMT.
'

usage="\n$(basename $0) [-h] [-s] [-t] [-d]\n\n

--Performs Preprocessing of T1 data and Diffusion data for microstructural informed tractography. Be sure to include full file paths.\n\n

i. Run Preprocess and T1Preprocess prior to this script.
1. perform response function estimation, CSD and tractography using WM, GM and CSF masks.
2. Connectivity can then be performed using T1 parcellation.

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
echo $ROOT
DWI_ROOT=$(echo $DWI | cut -d "/" -f 9)
echo $DWI_ROOT
DWI_ROOT=$(echo $DWI_ROOT | cut -d "_" -f 1-2)

module load fsl
export FSLOUTPUTTYPE="NIFTI_GZ"
module load ants
module load freesurfer
module load mrtrix3/b2
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTDIR="${ROOT}"

WMMASK="${ROOT}/WM_mask"
GMMASK="${ROOT}/GM_mask"
CSFMASK="${ROOT}/CSF_mask"
# Convert WM mask to mif format
#rconvert brain brain.nii
#mrconvert apar+aseg aparc+aseg.nii
# register brain to native

flirt -in "${ROOT}/${DWI_ROOT}_freesurfer/mri/brain.nii.gz" -ref "${ROOT}/T1_coreg_diffbrain_restore.nii.gz" \
 -out "${ROOT}/${DWI_ROOT}_freesurfer/mri/brain.nii.gz" -omat "${ROOT}/${DWI_ROOT}_freesurfer/mri/braindiff.mat"

# register atlas to native
flirt -in "${ROOT}/${DWI_ROOT}_freesurfer/mri/aparc.DKTatlas+aseg.nii.gz" \
-ref "${ROOT}/T1_coreg_diffbrain_restore.nii.gz" -applyxfm -init  "${ROOT}/${DWI_ROOT}_freesurfer/mri/braindiff.mat" \
-out "${ROOT}/DKTaltas_aseg.nii.gz" -interp nearestneighbour


mrconvert "${WMMASK}.nii.gz" "${WMMASK}.mif"

################################## CONSTRAINED SPHERICAL DECONVOLUTION #################################################

# Response Function Estimation - Multi Shell Multi Tissue Response Function Estimation.
dwi2response dhollander "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" "${ROOT}/wm.txt" "${ROOT}/gm.txt" "${ROOT}/csf.txt" \
-voxels voxel.mif -force

# FODF Estimation - apply basis functions to diffusion data
# S = R x FOD, the signal is the response function convolved with our fodf, we have the signal, so if we
# deconvolve the signal and the response function we can obtain the fodf.
dwi2fod msmt_csd "${ROOT}/${DWI_ROOT}_dwi_preproc.mif" -mask "${ROOT}/${DWI_ROOT}_BrainMask.nii.gz" "${ROOT}/wm.txt" \
 "${ROOT}/wmfod.mif" "${ROOT}/gm.txt" "${ROOT}/gmfod.mif" "${ROOT}/csf.txt" "${ROOT}/csffod.mif" -force

mrconvert -coord 3 0 "${ROOT}/wmfod.mif" - | mrcat "${ROOT}/csffod.mif" "${ROOT}/gmfod.mif" - "${ROOT}/vf.mif" -force
# To visualize
#mrview vf.mif -odf.load_sh wmfod.mif

# normalize fodfs
mtnormalise "${ROOT}/wmfod.mif" "${ROOT}/wmfod_norm.mif" "${ROOT}/gmfod.mif" \
 "${ROOT}/gmfod_norm.mif" "${ROOT}/csffod.mif" "${ROOT}/csffod_norm.mif" -mask "${ROOT}/${DWI_ROOT}_BrainMask.nii.gz"

# Perform 5ttgen to get seed and register
5ttgen fsl "${ROOT}/${DWI_ROOT}.mif" "${ROOT}/5tt_nocoreg.mif"
mrconvert "${ROOT}/5tt_nocoreg.mif" "${ROOT}/5tt_nocoreg.nii.gz"
fslroi "${ROOT}/5tt_nocoreg.nii.gz" "${ROOT}/5tt_nocoreg_vol0.nii.gz" 0 1
flirt -in "${ROOT}/5tt_nocoreg_vol0.nii.gz" -ref "${ROOT}/T1_coreg_diffbrain.nii.gz" -out "${ROOT}/5tt_nocoreg_diff.nii.gz" \
-omat "${ROOT}/5tt_nocoreg_diff.mat"
flirt -in "${ROOT}/5tt_nocoreg.nii.gz" -ref "${ROOT}/T1_coreg_diffbrain.nii.gz" -out "${ROOT}/5tt_nocoreg.nii.gz" \
-applyxfm -init "${ROOT}/5tt_nocoreg_diff.mat" -out "${ROOT}/5tt_coreg.nii.gz"
mrconvert "${ROOT}/5tt_coreg.nii.gz" "${ROOT}/5tt_coreg.mif" -force
# obtain seed
# Create WM/GM interface
5tt2gmwmi "${ROOT}/5tt_coreg.nii.gz" "${ROOT}/gmwmSeed_coreg.mif"

####################################### TRACTOGRAPHY ###################################################################
# max length
# cutoff - FOD amplitude cutoff
tckgen -act "${ROOT}/5tt_coreg.nii.gz" -backtrack -seed_gmwmi "${ROOT}/gmwmSeed_coreg.mif" -nthreads 8 -maxlength 250 \
-cutoff 0.06 -select 10000000 "${ROOT}/wmfod_norm.mif" "${ROOT}/tracks_10M.tck"
tcksift2 -act "${ROOT}/5tt_coreg.nii.gz" -out_mu "${ROOT}/sift_mu.txt" -out_coeffs "${ROOT}/sift_coeffs.txt" \
-nthreads 8 "${ROOT}/tracks_10M.tck" "${ROOT}/wmfod_norm.mif" "${ROOT}/sift_1M.txt"
# still have false positives and false negatives
tckedit "${ROOT}/tracks_10M.tck" -number 200k "${ROOT}/smallerTracks_200k.tck"

# Next step is to create the connectome.
