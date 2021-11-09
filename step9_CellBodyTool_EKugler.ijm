/* Quantification of MG number of cell bodies in segmented images
 * Author: Elisabeth Kugler 2021
 * contact: kugler.elisabeth@gmail.com

BSD 3-Clause License

Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom]
All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


///// GUI /////
Dialog.create("Cell body analysis tool");
BinaryChoice = newArray("no","yes");

Dialog.addChoice("One manual ROI:", BinaryChoice);
Dialog.addMessage("Input data need to be segmented.");	

// create dialog
Dialog.show();
// parse choices and input
manualROI = Dialog.getChoice(); 


// -- input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// create output folders
OutputDir = path + "/CellBodies/"; 
File.makeDirectory(OutputDir);
OutputDirMIPs = OutputDir + "/MIPs/"; 
File.makeDirectory(OutputDirMIPs);
// output file
f = File.open(path + "QuantificationResultsCB.txt"); // display file open dialog
print(f, "name" + "\t" + "nucleiNr");

// set colours and measurements
setForegroundColor(0, 0, 0); 
setBackgroundColor(255, 255, 255);
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// get ROI for manual ROI
if (manualROI==BinaryChoice[1]){ // yes - get ROI
	// open 1 ROI
	roiManager("Open", path + "ROI.roi");
}

// global vars
var nNuclei = 0;
var MGPos = 0;
var MGWidth = 0;
var MGPosvx = 0;
var MGWidthvx = 0;


// iterate through images
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".tif")) {
	// show rogress
	showProgress(i+1, sortedFilelist.length);
	print("processing ... " + sortedFilelist[i]);

	open(path + sortedFilelist[i]);
	imgName=getTitle();
	img = replace(imgName, ".tif", "");

	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);

	
	if (manualROI==BinaryChoice[0]){ // no - automatically select ROI
		cellBodyPosFrom1DVector(sortedFilelist[i]);

		// extract CBs in image by cropping using rectangular ROI from 1D vector
		selectWindow(sortedFilelist[i]);
		
		setTool("rectangle");
		
		// translate back from 1D vector to 3D stack
		MGPosvx = MGPos / pixelHeight; // this will be the start point from the top
		MGWidthvx = MGWidth / pixelHeight;
		
		// get 10um attached above and below box to account for retina curvature
		EnlargeBox = 10 / pixelHeight; 
	
		MGPosvxLarger = MGPosvx - EnlargeBox; // start further up
		MGWidthvxLarger = MGWidthvx + (2 * EnlargeBox); // extend box down
		// create rectangle that starts from the top where CBs are,
		// starts at the very left, is as wide as the img, and as high as CBs
		//makeRectangle(0, MGPosvx, width, MGWidthvx); // x, y, width, height
		makeRectangle(0, MGPosvxLarger, width, MGWidthvxLarger); // x, y, width, height
		
	}else{ // yes - prompt user to draw ROI
		// select ROI from ROI manager - this ROI needs to be drawn before Macro starts
		roiManager("Select", 0);
	}
	// quantification of cell bodies
	selectWindow(sortedFilelist[i]);
	quantifyCellNr(sortedFilelist[i]);
	
	close("*");
	}
}

close("*");
run("Collect Garbage");

// show message when Macro is finished
showMessage("Macro is finished"); 

///// FUNCTIONS /////
function cellBodyPosFrom1DVector(img) { 
	//----- select subregions of CBs using zonationTool approach
	// make 1D vectors
	// reduce in z-axis
	run("Z Project...", "projection=[Average Intensity]");
	// reduce in x-axis
	run("Reslice [/]...", "output=1.000 start=Left");
	run("Z Project...", "projection=[Average Intensity]");
	// TH 1D vector
	run("8-bit");
	//run("Auto Local Threshold", "method=Bernsen radius=5 parameter_1=0 parameter_2=0 white");

	run("Gaussian Blur...", "sigma=6");
	setAutoThreshold("Otsu dark");
	run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");

	run("Invert");

	// extract largest ROI - should be CBs
	run("Analyze Particles...", "size=10-Infinity pixel display clear in_situ"); // set Analyses params above	
	
	MeasX = newArray(nResults());
	MeasWidth = newArray(nResults()); // width in microns
	// get position info and width
	for (i=0;i<nResults();i++){
		MeasX[i] =  getResult("BX", i);
		MeasWidth[i] =  getResult("Width", i);
	}
	
	close("Results");
	saveAs("Jpeg", OutputDirMIPs + "MAX_CBsTH_" + img);
	close("MAX_CBsTH_" + img);

 	// need to get the block with "maximum width" (i.e. MG cell bodies) - FROM THIS block take the position
 	Array.getStatistics(MeasWidth, min, max, mean, std); // get array stats for block width's
	maxVal = indexOfArray(MeasWidth, max); // get idx of array position (see fct below)
	MGWidth = max;
	MGPos = MeasX[maxVal];
}


function quantifyCellNr(title) { 
	run("Duplicate...", "duplicate");
	
	saveAs("Tiff", OutputDir + "CBs_crop_" + img);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPs + "MAX_CBs_crop_" + img);
	close();
	
	selectWindow("CBs_crop_" + imgName);
	
	//----- 3D watershed to separate CBs
	run("Distance Transform Watershed 3D", "distances=[Chessboard (1,1,1)] output=[16 bits] normalize dynamic=4 connectivity=26");
	
	// Threshold to binarize before analysing CBs
	halfPos = round(slices / 2);
	setSlice(halfPos);
	// binarize the watershedded img
	run("3D Simple Segmentation", "low_threshold=1 min_size=0 max_size=-1");
	selectWindow("Seg");
	close();
	selectWindow("Bin");
	rename(sortedFilelist[i]);
	run("Make Binary", "method=Otsu background=Dark");
	saveAs("Tiff", OutputDir + "CBs_TH_" + img);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPs + "MAX_CBs_TH_" + img);
	close();

	//----- BoneJ analyser to analyse CBs
	run("Particle Analyser", "surface_area euler min=50 max=Infinity surface_resampling=2 show_particle surface=Gradient split=0.000 volume_resampling=2"); // 50 is um3 minimum cut-off
	
	// save image
	saveAs("Tiff", OutputDir + "CBs_Analysed_" + img);
	run("Z Project...", "projection=[Max Intensity]");
	run("16 colors");
	saveAs("Jpeg", OutputDirMIPs + "MAX_CBs_" + img);
	close();
	close();
	// save results
	nNuclei = nResults();
	saveAs("Results", OutputDir + img + ".csv");
	close("Results");
	
	print(f, sortedFilelist[i] + "\t" + nNuclei);

}


function indexOfArray(array, value) {
// http://imagej.1557.x6.nabble.com/Find-x-value-of-profile-maximum-or-array-td3683111.html
// Returns the indices at which a value occurs within an array
// needed to get max Value of zonationTool

    count=0;
    for (i=0; i<lengthOf(array); i++) {
        if (array[i]==value) {
            count++;
        }
    }
    if (count>0) {
        indices=newArray(count);
        count=0;
        for (i=0; i<lengthOf(array); i++) {
            if (array[i]==value) {
               // indices[count]=i;
               maxVal = i; // only need one value, namely the max
               count++;
            }
        }
      //  return indices;
      return maxVal;
    }
}
