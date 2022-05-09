# GliaMorph Introduction

GliaMorph Toolkit to process and analyse Müller glia morphology (implemented as Fiji Macros to allow modular application).

BioRxiv manuscript - GliaMorph biological application: https://www.biorxiv.org/content/10.1101/2022.05.05.490765v1

BioRxiv manuscript - step-by-step protocol: XXX <br/>
Example Data: **Data Link**: https://zenodo.org/record/5747597 **DATA DOI**: 10.5281/zenodo.5747597

Minimum Example Data 29112021: **Data Link**: https://zenodo.org/record/5735442 **DATA DOI**: 10.5281/zenodo.5735442

YouTube Screencasts: https://www.youtube.com/hashtag/gliamorph (recorded by Sara Beqiri and Karim Nizam, 2022)

**Code Author**: Elisabeth Kugler <br/>
**Project Leads**: Elisabeth Kugler (code, formal analysis, supervision) and Ryan MacDonald (data, resources, supervision) <br/>
**Project Contributors**: Eva-Maria Breitenbach (tester), Alicia Carrington (data and tester), Isabel Bravo (data and tester), Stefania Marcotti (code: https://github.com/OakesLab/AFT-Alignment_by_Fourier_Transform), Brian M. Stramer (resources), and Pierre Mattar (data and resources). <br/>
**Contact**: kugler.elisabeth[at]gmail.com<br/>

BSD 3-Clause License <br/>
Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom] <br/>
All rights reserved.

![Eli's GitHub stats](https://github-readme-stats.vercel.app/api?username=ElisabethKugler&show_icons=true)
[![Top Langs](https://github-readme-stats.vercel.app/api/top-langs/?username=ElisabethKugler&layout=compact)](https://github.com/ElisabethKugler/github-readme-stats)


## Contributions and Feedback
This GitHub repository will be maintained until at least 2023 by Elisabeth Kugler. However, as #GliaMorph tools are meant to be used and useful, the code and tools are meant to change and be adaptable. Please help us make the most out of #GliaMorph:

- Raise issues for improvements and create pull requests for code adaptions in Github (as described by Robert Haase: https://focalplane.biologists.com/2021/09/04/collaborative-bio-image-analysis-script-editing-with-git/).
- Contribute to the discussion (https://github.com/ElisabethKugler/GliaMorph/discussions). 
- Use the image.sc forum for discussions / questions / how-to's (https://forum.image.sc/)
- Please use the hashtag #GliaMorph (especially on social media), so we can communicate effectively around the tool.
- For specific questions, please contact kugler.elisabeth[at]gmail.com.

## Overview of Steps

- **step1_cziToTiffTool.ijm**: Macro for czi to tiff conversion

- **step2_DeconvolutionTool.ijm**: Macro for deconvolution of confocal images using theoretical or experimental PSF

- **step3_90DegreeRotationTool.ijm**: Macro for 90 degree rotation - optional before rotationTool

- **step4_subregionTool.ijm**: Semi-automatic ROI selection tool with ROI selection from MIP

- **step4_subregionToolWithinStack.ijm**: Semi-automatic ROI selection tool within stack with ROI within stack

- **step5_splitChannelsTool.ijm**: Macro to split channels and save them in separate folders

- **step6_zonationTool.ijm**: Analysis of zebrafish retina zonation based on intensity profiles

- **step7_SegmentationTool.ijm**: Segmentation of MG cells

- **step8_QuantificationTool.ijm**: Quantification of MG features in segmented images


# Required Fiji Update sites and Extensions
## Fiji Update Sites
1.	“Fiji > Help > Update > Manage update sites”
2.	Select “3D ImageJ Suite”, “Neuroanatomy”, and “IJBP-Plugins” 
3.	Click “Close” 
4.	Click “Apply Changes”. 

## Extensions
Both are required for the point spread function (PSF) deconvolution. 

a) Extension 1: Diffraction PSF 3D to generate a theoretical PSF: details at https://www.optinav.info/Iterative-Deconvolve-3D.htm
Download “Diffraction_PSF_3D.class” from https://github.com/ElisabethKugler/GliaMorph (found under “other”) - copy and paste this it into Fiji > Plugin folder > restart Fiji. Check if "Plugins > Diffraction PSF 3D" is there.
(Author: Bob Dougherty; Permission: 13.12.2021 - via email between Bob Dougherty and Elisabeth Kugler; Link: https://www.optinav.info/Diffraction-PSF-3D.htm; Licence: Copyright (c) 2005, OptiNav, Inc.All rights reserved).

b) Extension 2: DeconvolutionLab2 for PSF deconvolution (Sage et al., 2017): follow the installation guide http://bigwww.epfl.ch/deconvolution/deconvolutionlab2/.


# #GliaMorph: Minimum Example Data 29112021 (see protocol for details)
Acquired by Dr Ryan MacDonald at the Institute of Ophthalmology, University College London (http://zebrafishucl.org/macdonald-lab).
Processed by Dr Elisabeth Kugler at the Institute of Ophthalmology, University College London (https://www.elisabethkugler.com/).

**Data Link**: https://zenodo.org/record/5735442#.YaUPG9DP02w
**DATA DOI**: 10.5281/zenodo.5735442

Good practice - close all unnecessary windows in Fiji and do not click things while Macros are running.

**#1** Three images of zebrafish retina at 3dpf in the double-transgenic Tg(TP1bglob:VenusPest)s940 (Ninov et al., 2012) and Tg(CSL:mCherry)jh11 (also known as Tg(Tp1bglob:hmgb1-mCherry)jh11 (Parsons et al., 2009). These are in the folder "ExampleData_GitHub_GliaMorph_KuglerEtAl".

**#2** application of step4_subregionTool.ijm: This will need "RoiSetLine.zip" to be drawn on the MIPs and be applied to the 3D stacks. It will deliver images that are comparable against each other (rotated, cropped in x-and-y, reduced in z) - based on user-selected parameters. For this example we leave the default parameters unchanged, which will deliver an image of width 60um, height as per ROI, depth of 15um, and a sigma of 10um (sigma is attached at the bottom of the ROI - this not only accounts for the MG curvature, but also allows inclusion of underlying blood vessels). This step only takes a few minutes.

**#3** application of step5_splitChannelsTool.ijm: Apply this step to the images in the folder "zDir" (these are the comparable images: rotated, cropped in x-and-y, reduced in z) to split channels - in this case, choose 2 as input parameter as the data are from double-transgenics with 2 channels. For the remaining steps we will focus on one of the reporter lines, namely Tg(Tp1bglob:hmgb1-mCherry)jh11. This step only takes a few minutes.

**#4** application of step6_zonationTool.ijm: Analyse texture / zonation - for our example, we do this for "2CDir" Tg(Tp1bglob:hmgb1-mCherry)jh11.
Parameters as follows: yes, no, 1920, 10 - we only change the second parameter to "no" - leave the others >> see image. This step only takes a few minutes.
![image]
(https://user-images.githubusercontent.com/67630046/143879883-ff37752a-ff5a-4a60-9ed9-a8922f688eb6.png)
see output data in the folder "ZonationTool"

**#5** application of step7_SegmentationTool.ijm: Next, we want to segment the data - for this we use again the stacks (i.e. 3D tiffs) from the folder "2CDir". The data will be segmented / binarized / thresholded and outputs will be saved in folder "TH" - these are again 3D stacks (MIP folder contained in the folder). This step only takes a little bit longer, but normally less than 5min per image.

**#6** application of step8_QuantificationTool.ijm: Quantification of MG parameters - this uses the folder "TH" as input - so this means 3D stacks that are segmented. This is the most time-consuming step, that can take up to about 40min per image depending on computer spec and image size.
