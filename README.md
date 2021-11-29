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
Please raise issues in Github (as described by Robert Haase: https://focalplane.biologists.com/2021/09/04/collaborative-bio-image-analysis-script-editing-with-git/) 
pr contribute to the discussion (https://github.com/ElisabethKugler/GliaMorph/discussions). 
As always, use the image.sc forum for discussions / questions / how-to's (https://forum.image.sc/)

Please use the hashtag #GliaMorph (especially on social media), so we can communicate effectively around the tool.

For specific questions, please contact kugler.elisabeth[at]gmail.com.

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

