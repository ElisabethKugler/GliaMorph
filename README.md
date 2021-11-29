# GliaMorph
GliaMorph Toolkit to process and analyse Muller glia morphology

Implemented as Fiji Macros

Publication: XXX

Step-by-step protocol: XXX

Author: Elisabeth Kugler 2021

Contact: kugler.elisabeth[at]gmail.com

BSD 3-Clause License

Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom]
All rights reserved.

## We always welcome contributions and feedback
This GitHub repository will be maintained until at least 2023 by Elisabeth Kugler. However, as it is meant to be used and useful, the code and tools are meant to change and be adaptable. Please help us make the most out of #GliaMorph:

- Raise issues in Github (as described by Robert Haase: https://focalplane.biologists.com/2021/09/04/collaborative-bio-image-analysis-script-editing-with-git/).
- Contribute to the discussion (https://github.com/ElisabethKugler/GliaMorph/discussions). 
- As always, use the image.sc forum for discussions / questions / how-to's (https://forum.image.sc/)
- Please use the hashtag #GliaMorph (especially on social media), so we can communicate effectively around the tool.
- For specific questions, please contact kugler.elisabeth[at]gmail.com.

## Overview of Steps

- **step1_cziToTiffTool_EKugler.ijm**: Macro for czi to tiff conversion

- **step2_DeconvolutionTool_EKugler.ijm**: Macro for deconvolution of confocal images using theoretical or experimental PSF

- **step3_90DegreeRotationTool_EKugler.ijm**: Macro for 90 degree rotation - optional before rotationTool

- **step4_subregionTool_EKugler.ijm**: Semi-automatic ROI selection tool with ROI selection from MIP

- **step4_subregionToolWithinStack_EKugler.ijm**: Semi-automatic ROI selection tool within stack with ROI within stack

- **step5_splitChannelsTool_EKugler.ijm**: Macro to split channels and save them in separate folders

- **step6_zonationTool_EKugler.ijm**: Analysis of zebrafish retina zonation based on intensity profiles

- **step7_SegmentationTool_EKugler.ijm**: Segmentation of MG cells

- **step8_QuantificationTool_EKugler.ijm**: Quantification of MG features in segmented images

## #GliaMorph: Minimum Example Data 29112021 (see protocol for details)
Acquired by Dr Ryan MacDonald at the Institute of Ophthalmology, University College London (http://zebrafishucl.org/macdonald-lab).
Processed by Dr Elisabeth Kugler at the Institute of Ophthalmology, University College London (https://www.elisabethkugler.com/).

**Data Link**: https://zenodo.org/record/5735442#.YaUPG9DP02w
**DATA DOI**: 10.5281/zenodo.5735442

Good practice - close all unnecessary windows in Fiji and do not click things while Macros are running.

**#1** Three images of zebrafish retina at 3dpf in the double-transgenic Tg(TP1bglob:VenusPest)s940 (Ninov et al., 2012) and Tg(CSL:mCherry)jh11 (also known as Tg(Tp1bglob:hmgb1-mCherry)jh11 (Parsons et al., 2009). These are in the folder "ExampleData_GitHub_GliaMorph_KuglerEtAl".

**#2** application of step4_subregionTool_EKugler.ijm: This will need "RoiSetLine.zip" to be drawn on the MIPs and be applied to the 3D stacks. It will deliver images that are comparable against each other (rotated, cropped in x-and-y, reduced in z) - based on user-selected parameters. For this example we leave the default parameters unchanged, which will deliver an image of width 60um, height as per ROI, depth of 15um, and a sigma of 10um (sigma is attached at the bottom of the ROI - this not only accounts for the MG curvature, but also allows inclusion of underlying blood vessels). This step only takes a few minutes.

**#3** application of step5_splitChannelsTool_EKugler.ijm: Apply this step to the images in the folder "zDir" (these are the comparable images: rotated, cropped in x-and-y, reduced in z) to split channels - in this case, choose 2 as input parameter as the data are from double-transgenics with 2 channels. For the remaining steps we will focus on one of the reporter lines, namely Tg(Tp1bglob:hmgb1-mCherry)jh11. This step only takes a few minutes.

**#4** application of step6_zonationTool_EKugler.ijm: Analyse texture / zonation - for our example, we do this for "2CDir" Tg(Tp1bglob:hmgb1-mCherry)jh11.
Parameters as follows: yes, no, 1920, 10 - we only change the second parameter to "no" - leave the others >> see image. This step only takes a few minutes.
![image]
(https://user-images.githubusercontent.com/67630046/143879883-ff37752a-ff5a-4a60-9ed9-a8922f688eb6.png)
see output data in the folder "ZonationTool"

**#5** application of step7_SegmentationTool_EKugler.ijm: Next, we want to segment the data - for this we use again the stacks (i.e. 3D tiffs) from the folder "2CDir". The data will be segmented / binarized / thresholded and outputs will be saved in folder "TH" - these are again 3D stacks (MIP folder contained in the folder). This step only takes a little bit longer, but normally less than 5min per image.

**#6** application of step8_QuantificationTool_EKugler.ijm: Quantification of MG parameters - this uses the folder "TH" as input - so this means 3D stacks that are segmented. This is the most time-consuming step, that can take up to about 40min per image depending on computer spec and image size.
