#!/usr/bin/env python3

"""
script to remove specific labels from an atlas volume such as WM and CSF (Ventricles).
Labels used here are based off of DKT atlas. 

based off of scilpy_remove_labels.py

usage: removeLabels.py in_labels.nii out_labels.nii 

"""
import argparse
import logging
import os
import nibabel as nib
import numpy as np
import matplotlib.pyplot as plt

def build_arg_parser():

    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("in_labels", type=str)
    p.add_argument("out_labels", type=str)
    p.add_argument("--background", type=int, default=0)
    args = p.parse_args()
    return args

def get_data_as_label(in_img):
    curr_type = in_img.get_data_dtype()
    basename = os.path.basename(in_img.get_filename())
    if np.issubdtype(curr_type, np.signedinteger) or \
            np.issubdtype(curr_type, np.unsignedinteger):
        return np.asanyarray(in_img.dataobj).astype(np.uint16)


def main():

    args = build_arg_parser()
    # args = parser.parse_args()

    #Load Volume
    label_img = nib.load(args.in_labels)
    label_volume = get_data_as_label(label_img)
    labels_to_keep = [0,8, 10, 11,12,13, 16,17,18, 26,28,47,49,50,
                      51,52,53,54,58,60,85,1000,1001,1002,1003,1005,1006,1008,1009,1010,1011,
                      1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,
                      1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,2000,2001,2002,2003,
                      2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,
                      2021,2022,2023,2024,2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035]

    for i in np.unique(label_volume):

        if i not in labels_to_keep:
            mask = label_volume == i
            label_volume[mask] = args.background
        else:
            # print(i)
            pass

    nii = nib.Nifti1Image(label_volume, label_img.affine, label_img.header)
    nib.save(nii, args.out_labels)


if __name__ == "__main__":
    main()