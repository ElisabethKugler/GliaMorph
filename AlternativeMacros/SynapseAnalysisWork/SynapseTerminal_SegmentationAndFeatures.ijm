/* Analysis of zebrafish IPL synapse terminal segmentation and feature analysis
 * EKugler May 2022
 * 
 * Author: Elisabeth Kugler 2020-2022
 * contact: kugler.elisabeth@gmail.com

BSD 3-Clause License

Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom]
All rights reserved.

(1) input images are single-channel (i.e. synapse staining like Ribeye) 3D stacks
(2) iterate over images in the folder 
(3) identify IPL
(4) segmentation of synapse terminals
(5) synapse terminal quantification
(6) write outputs

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// ---- prompt user for path to input images
// input images are single-channel (i.e. synapse staining like Ribeye) 3D stacks
pathIPL = getDirectory("Input Folder: Raw synapse terminal data"); 
filelistIPL = getFileList(pathIPL);
sortedFilelist = Array.sort(filelistIPL);

print("Input Directory: " + pathIPL);

OutputDirpathIPL = pathIPL + "/OutputDirIPL/"; 
File.makeDirectory(OutputDirpathIPL);

setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);


// varibables for IPL ROI selection (global)
var j = 0;
var k = 0;
var Largest = 0;

// set measurements for IPL extraction
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");
// set 3D object counter settings
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 show_numbers white_numbers store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");

// ---- processing
for (i=0; i< sortedFilelist.length; i++) {
		if (endsWith(sortedFilelist[i], ".tif")) {
			open(pathIPL + sortedFilelist[i]);
			selectWindow(sortedFilelist[i]);
			
			// call fct to identify IPL
			IPLidentification(sortedFilelist[i]);
		
			img=getTitle();
			rename("imgN");

			// intensity adjustment - 11052021
			getDimensions(width, height, channels, slices, frames);
			halfPos = round(slices / 2);
			setSlice(halfPos);
			run("Enhance Contrast", "saturated=0.35");
			run("Apply LUT", "stack");
			
			// pre-process
			run("8-bit");
			run("Subtract Background...", "rolling=50 stack");
			run("Gaussian Blur 3D...", "x=2 y=2 z=2");
			
			// 3D spot segmentation to segment /extract 3D synapse terminals
			run("3D Spot Segmentation", "seeds_threshold=15 local_background=65 local_diff=0 radius_0=2 radius_1=4 radius_2=6 weigth=0.50 radius_max=10 sd_value=1 local_threshold=Constant seg_spot=Classical watershed volume_min=10 volume_max=1000000 seeds=Automatic spots=imgN radius_for_seeds=2 output=[Label Image]");
			// save 3D segmented image
			saveAs("Tiff", OutputDirpathIPL + "3DSegm_" + sortedFilelist[i]);
			rename("Segm");

			selectWindow("imgN");
			close();
			selectWindow("Segm");
			// produce colour-labeled MIP
			run("Color Balance...");
			run("Enhance Contrast", "saturated=0.35");
			run("Duplicate...", "duplicate");
			run("16 colors");
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Jpeg", OutputDirpathIPL + "MAX_3DSegm" + sortedFilelist[i]);
			close();
			
			// quantify synapse terminal properties using 3D object counter
			selectWindow("Segm");
			run("3D Objects Counter", "threshold=1 slice=29 min.=5 max.=138366918 objects surfaces centroids centres_of_masses statistics summary");
			selectWindow("Objects map of Segm");
			saveAs("Tiff", OutputDirpathIPL + "Objects_" + sortedFilelist[i]);
			close();
			// save 3D object counter outputs
			selectWindow("Surface map of Segm");
			saveAs("Tiff", OutputDirpathIPL + "Surface_" + sortedFilelist[i]);
			close();
			selectWindow("Centroids map of Segm");
			saveAs("Tiff", OutputDirpathIPL + "Centroid_" + sortedFilelist[i]);
			close();
			selectWindow("Centres of mass map of Segm");
			saveAs("Tiff", OutputDirpathIPL + "CM_" + sortedFilelist[i]);
			close();
			// save results
			selectWindow("Statistics for Segm");
			saveAs("Results", OutputDirpathIPL + "3DObjCounter_" + sortedFilelist[i] + ".csv");

			close("*");
		}
}

//selectWindow("Log");
//saveAs("Text", OutputIx + "3DObjCounter_analysisSummary.txt");

print("Output Directory: " + OutputDirpathIPL);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// show message when MacrosetSlice(halfPos); is finished
showMessage("Macro is finished"); 

// function to automatically extract IPL from 3D stack
// it basically tries to "block out" the IPL - then uses the largest image ROI for image cropping
function IPLidentification(title){
	// correct z-axis signal decay
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	run("Z Project...", "projection=[Max Intensity]");
	// smooth to achieve more coherent coverage
	run("Gaussian Blur...", "sigma=15");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	run("Analyze Particles...", "size=300-Infinity pixel display clear add in_situ");
	selectWindow("MAX_DUP_" + title);
	close();
	
	// select 3D stack
	selectWindow("DUP_" + title);

	// if there are multiple ROIs > assume that's the IPL > select the largest one
	if (roiManager("count")>1);{
	        Area=newArray(roiManager("count"));
	        
	        for (j=0; j<roiManager("count");j++){
	                roiManager("select", j);
	                getStatistics(Area[j], mean, min, max, std, histogram);
	        }
	        counter = 0;
	        
	        for (j=0; j<(roiManager("count"));j++){
	                if (Area[j]>counter){
	                        counter=Area[j];
	                        Largest = j;
	                }
	        }
	}
	roiManager("Select", Largest);
	
	// save ROI with the image name
	roiManager("Rename", title);
	roiManager("Save", OutputDirpathIPL + title + ".roi");
	run("Clear Outside", "stack"); //11052021
	run("Crop");
	roiManager("Select", Largest);
	roiManager("Delete");
}

