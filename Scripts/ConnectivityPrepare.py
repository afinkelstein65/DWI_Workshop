import os
import argparse
from argparse import ArgumentParser
import nibabel as nib
from dipy.tracking import utils

# Script on Generating connectivity matrices
'''
Script to generate connectivity matrices - use as a template. Written for CABIN DWI Workshop 2023. 
Can also use connectoflow. 

Author: Alan Finkelstein
Date: 2/2023
email: alan_finkelstein@urmc.rochester.edu
'''

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os

def parser():

    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("label_file", type=str)
    p.add_argument("out_file", type=str)
    p.add_argument("--tractogram", type=str)
    p.add_argument("--show", type=bool, default=False)
    args = p.parse_args()
    return args


def get_data_as_label(in_img):
    curr_type = in_img.get_data_dtype()
    basename = os.path.basename(in_img.get_filename())
    if np.issubdtype(curr_type, np.signedinteger) or \
            np.issubdtype(curr_type, np.unsignedinteger):
        return np.asanyarray(in_img.dataobj).astype(np.uint16)


def show_labels(label_volume):
    plt.figure()
    plt.imshow(np.rot90(label_volume[:,:, 50]), cmap='jet')
    plt.axis('off')
    plt.show()
    return None

def updateLabels(label_file):

    label_img = nib.load(label_file)

    label_volume = get_data_as_label(label_img)
    orig_labels = [0,8, 10, 11, 12, 13, 16, 17, 18, 26, 28, 1000, 1001, 1002, 1003, 1005, 1006, 1008, 1009, 1010, 1011,
                      1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025,
                      1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1035, 47, 49, 50,
                      51, 52, 53, 54, 58, 60, 85, 2000, 2001, 2002, 2003,
                      2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020,
                      2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032, 2033, 2034, 2035]
    label_new = [i for i in range(len(orig_labels))]
    label_dict = dict(zip(orig_labels, label_new))

    for i in range(label_volume.shape[0]):
        for j in range(label_volume.shape[1]):
            for k in range(label_volume.shape[2]):
                if label_volume[i,j,k] != 0:
                    label_volume[i,j,k] = label_dict[label_volume[i,j,k]]

    return label_img, label_volume


def main():
    args = parser()
    label_img, label_volume = updateLabels(args.label_file)
    if args.show:
        show_labels(label_volume)

    niftiImage = nib.Nifti1Image(label_volume, label_img.affine,
                                 label_img.header)
    nib.save(niftiImage, args.out_file)

    return None


if __name__ == "__main__":

    main()