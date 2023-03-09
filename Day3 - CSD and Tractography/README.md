# DWI Workshop Day 3 - CSD and Tractography 

## Overview: 

In today's workshop we will take previously pre-processed data and perform constrained spherical deconvolution and tractography. 


## Sections: 

* [Constrained Spherical Deconvolution](DWI_Workshop_Day3_CSD.ipynb) 
* [Tractography](DWI_Workshop_Day3_Tractography.ipynb)


## Constrained Spherical Deconvolution: 

Need to estimate the fODF based on the response function and measured signal. Can use [CSD](https://mrtrix.readthedocs.io/en/dev/constrained_spherical_deconvolution/constrained_spherical_deconvolution.html) or [MSMT-CSD](https://mrtrix.readthedocs.io/en/dev/constrained_spherical_deconvolution/multi_shell_multi_tissue_csd.html), or more recently [SS3T-CSD](https://3tissue.github.io/doc/ss3t-csd.html). 


## Tractography: 

Run Preprocess.sh, T1preprocess.sh and then Tractography.sh. From here go on to perform bundle branch analysis, or connectivity and graph theory analysis. 

## Resources: 

1. [Tractoflow](https://github.com/scilus/tractoflow) - A pipeline that takes raw DWI, b-values, b-vectors, T1w to process DTI, fODF metrics, and whole brain tractogram. 
2. [Connectoflow](https://github.com/scilus/connectoflow) - Connectivity pipeline using Nextflow and Singularity Container. 