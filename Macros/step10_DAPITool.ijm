/* Measurement of number of DAPI stained nuclei
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

// This macro takes original DAPI stained images as input > performs segmentation > counts number of DAPI nuclei


///// prompt for input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// output folders
OutputDirDAPI = path + "/CellBodiesDAPI/"; 
File.makeDirectory(OutputDirDAPI);
OutputDirMIPsDAPI = path + "/MIPsDAPI/"; 
File.makeDirectory(OutputDirMIPsDAPI);

// output file that will contain file names and number of nuclei
D = File.open(path + "QuantificationResultsDAPI.txt"); // display file open dialog
print(D, "name" + "\t" + "DAPI nuclei");

// setBatchMode(true); //batch mode on

// set colours
setForegroundColor(0, 0, 0); 
setBackgroundColor(255, 255, 255);

var DAPINr = 0;

// iterate through images in input folder
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".tif"
	if (endsWith(sortedFilelist[i], ".tif")) {
	// show rogress
	showProgress(i+1, sortedFilelist.length);
	print("processing ... " + sortedFilelist[i]);

	open(path + sortedFilelist[i]);
	imgName=getTitle();
	
	// call fct DAPI counter
	DAPICounter(sortedFilelist[i]);
	close("*");
	}
}

run("Close All");
run("Collect Garbage");

showMessage("Macro is finished"); // show message when Macro is finished
// .. Macro finished .. // 

///// FUNCTIONS /////
function DAPICounter(title) { 
// This function quantifies the number of DAPI stained nuclei in a 3D stack
// after segmentation, using "3D shape measurement".

	// get image dimensions
	getDimensions(width, height, channels, slices, frames);
	halfPos = round(slices / 2);
	setSlice(halfPos);

	run("Enhance Contrast", "saturated=0.35");

	// iterate through slices and apply CLAHE to each slide (correct for brighter DAPI staining in the periphery than centre)
	for (k=1; k<nSlices+1;k++) {
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
		setSlice(k);
	}

	// Bleach correction in stack (first images in confocal microscopy are significantly brighter > correct for z-axis signal decay)	
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	
	// rescale to make image smaller to increase speed for watershedding and nuclei counting
	halfHeight = round(height/2);
	halfWidth = round(width/2);
	run("Scale...", "x=- y=- z=1.0 width=" + halfWidth + " height=" + halfHeight + " depth=" + slices + " interpolation=Bilinear average process create");

	wait(5000);

	// produce Gaussian filtered img with 2 different scales
	run("Duplicate...", "duplicate");
	rename("G3");
	run("Gaussian Blur 3D...", "x=3 y=3 z=3");
	run("Duplicate...", "duplicate");
	rename("G5");
	run("Gaussian Blur 3D...", "x=5 y=5 z=5");
	// DoG to produce "edges of nuclei" aka "BG"
	imageCalculator("Subtract create stack", "G5","G3");
	saveAs("Tiff", OutputDirDAPI + "DoG_" + sortedFilelist[i]);
	close("G3");
	close("G5");

	selectWindow("DoG_" + sortedFilelist[i]);
	
	// segmentation of the BG image
	rename("BG");
	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");
	setAutoThreshold("Otsu stack");
	//setThreshold(0, 73);
	run("Convert to Mask", "method=Otsu background=Light");
	run("Invert", "stack");
	
	// segmentation of the original image
	selectWindow(imgName);

	// check if scaled
	getDimensions(width, height, channels, slices, frames);
	if (height != halfHeight){ // not scaled
		run("Scale...", "x=- y=- z=1.0 width=" + halfWidth + " height=" + halfHeight + " depth=" + slices + " interpolation=Bilinear average process create");
	}

	// adjust contrast
	setSlice(halfPos);
	run("Color Balance...");
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");

	// use Gaussian filter for smoothing
	run("Gaussian Blur 3D...", "x=3 y=3 z=3");
	// remove background using rolling ball algorithm
	run("Subtract Background...", "rolling=400 stack");
	wait(3000);
	run("8-bit");

	// Otsu TH for segmentation
	setAutoThreshold("Otsu");
	run("Threshold...");
	setAutoThreshold("Otsu stack");
	run("Convert to Mask", "method=Otsu background=Light");
	run("Invert", "stack");
	rename("THImg"); // segmented original img
	
	// subtract segmented BG from segmented image to get nuclei that are better separated
	imageCalculator("Subtract create stack", "THImg","BG");
	// run 3D watershedding to separate nuclei that are still connected
	run("Distance Transform Watershed 3D", "distances=[Chessboard (1,1,1)] output=[16 bits] normalize dynamic=4 connectivity=26");
	rename("WS");
	
	// save MIP watershedded nuclei
	run("16 colors");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPsDAPI + "MAX_WS_" + sortedFilelist[i]);

	// binarize image after watershedding
	selectWindow("WS");
	setSlice(halfPos);
	run("Threshold...");
	setAutoThreshold("Otsu stack");
	setThreshold(0, 1);
	run("Convert to Mask", "method=Otsu background=Light");
	run("Invert", "stack");
	
	// save tiff 3D
	saveAs("Tiff", OutputDirDAPI + "TH_" + sortedFilelist[i]);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPsDAPI + "MAX_TH_" + sortedFilelist[i]);

	selectWindow("TH_" + sortedFilelist[i]);
	
	// measure number of DAPI stained nuclei
	run("3D Shape Measure"); // measurements go to "Results" window 
	wait(10000);
	// this were "xxx::Segmented" comes from - we do not actually need/use that
	
	// run("16-bit");
//	Ext.Manager3D_AddImage();
//	Ext.Manager3D_Measure();
	
	// nr of results is the nr of nuclei
	DAPINr = nResults();

	// print file name and respective nr of nuclei into output file
	print(D, sortedFilelist[i] + "\t" + DAPINr);
	close("Results");
}
