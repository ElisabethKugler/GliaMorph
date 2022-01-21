/* Macro for preliminary assessment of segmentation outcomes 
 * EKugler Aug 2021

 * Author: Elisabeth Kugler 2021
 * Copyright 2021 Elisabeth Kugler
 * contact: kugler.elisabeth@gmail.com

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

path = getDirectory("Input Folder"); 
filelist = getFileList(path);

outputFolder = path + "/SegmentationTesting/";
File.makeDirectory(outputFolder);

outputFolderMIPs = outputFolder + "/MIPs/";
File.makeDirectory(outputFolderMIPs)

for (i=0; i< filelist.length; i++) {   
	if (endsWith(filelist[i], ".tif")) {
		// open img
		open(path + filelist[i]);
		selectWindow(filelist[i]);

		// go to middle of stack (auto-threshold selection works best when in centre)
		getDimensions(width, height, channels, slices, frames);
		halfPos = round(slices / 2);
		setSlice(halfPos);
		
	//	preprocessing(filelist[i]); // function to smoothen image and remove background
		thresholding(filelist[i]); // function to test different thresholding approaches for image segmentation
		close("*");
	}
}

run("Collect Garbage");
run("Close All");
showMessage("Macro is finished"); 

///////////////// FUNCTIONS /////////////////
//-- PreProcessing
function preprocessing(title) {
	// smooth
	run("Median 3D...", "x=3 y=3 z=3"); // filter-size can be changed
	wait(1000);
	// remove background
	run("Subtract Background...", "rolling=100 stack"); // filter-size can be changed
	wait(1000);
}

//-- Testing different thresholding methods
function thresholding(title) {
	run("3D Hysteresis Thresholding", "high=110 low=30 show labelling"); // low and high can be changed
	
	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");

	run("8-bit");
	setOption("BlackBackground", false);
	setThreshold(0, 0);
	run("Make Binary", "method=Otsu background=Default");
	run("Invert", "stack");
	
	saveAs("Tiff", outputFolder + "3DHyst_" + filelist[i]); 
	//run("Invert", "stack");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_3DHyst128-50_" + filelist[i]);
	close("*");
}