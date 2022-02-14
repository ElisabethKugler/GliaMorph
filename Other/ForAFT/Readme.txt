Fiji Macros for processing before adapted AFT analysis (see: https://github.com/OakesLab/AFT-Alignment_by_Fourier_Transform/tree/master/MATLAB_implementation)
- CheckImageSize.ijm: provides maximum image height of all images in a subfolder > run on several subfolders e.g. ctrl and treatment to find "maxHeight"
- NormalizeImageSizes.ijm: preprocess images to improve signal, 8-bit conversion, and adjust canvas size by providing "maxHeight" 
(method: centre top alignment)