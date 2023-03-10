#!/bin/bash

: <<COMMENTBLOCK
This code calls flirt to reslice an image isotropically. It defaults to
trilinear interpolation on most images, but if you give it a mask and the optional 3rd argument, it uses nearest neighbour interpolation to preserve the binary nature of the mask.
COMMENTBLOCK


# Exit if number of arguments is too small
if [ $# -lt 2 ]
    then
        echo "======================================================"
        echo "Two arguments are required. An optional 3rd argument can be added to reslice a mask and keep it binary"
        echo "argument 1: name of NIFTI image to reslice"
        echo "argument 2: size in mm of the resliced image (e.g., 0.47 or 1)"
        echo "optional argument 3: enter mask if this is a mask image"
        echo "e.g., $0 anat_CT 0.443"
        echo "e.g., $0 lesion_mask 0.443 mask"
        echo "output will be named with size in mm appended, e.g., anat_CT_0.433mm.nii.gz"
        echo "======================================================"
        exit 1
fi

# get the input stem
input=$(remove_ext ${1})
size=${2}
mask=${3}

# If there are 2 arguments
if [ $# -eq 2 ]; then
  flirt -in ${input} -ref ${input} -applyisoxfm ${size} -out ${input}_${size}mm -interp nearestneighbour
# else if there are more than 2 arguments and the 3rd argument is mask
elif [ $# -gt 2 ] && [ ${mask} = "mask" ]; then
  echo "This is a mask image and will use nearest neighbour interpolation for reslicing"
  flirt -in ${input} -ref ${input} -applyisoxfm ${size} -interp nearestneighbour -out ${input}_${size}mm
# For anything else, spit out the help message and stop.
else
  echo "======================================================"
  echo "Two arguments are required. An optional 3rd argument can be added to reslice a mask and keep it binary"
  echo "argument 1: name of NIFTI image to reslice"
  echo "argument 2: size in mm of the resliced image (e.g., 0.47 or 1)"
  echo "optional argument 3: enter mask if this is a mask image"
  echo "e.g., $0 anat_CT 0.443"
  echo "e.g., $0 lesion_mask 0.443 mask"
  echo "output will be named with size in mm appended, e.g., anat_CT_0.433mm.nii.gz"
  echo "======================================================"
  exit 1
fi