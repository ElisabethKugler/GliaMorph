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
sortedFilelist = Array.sort(filelist);

outputFolder = path + "/SegmentationTesting/";
File.makeDirectory(outputFolder);

outputFolderMIPs = outputFolder + "/MIPs/";
File.makeDirectory(outputFolderMIPs)

for (i=0; i< sortedFilelist.length; i++) {   
	if (endsWith(sortedFilelist[i], ".tif")) {
		// open img
		open(path + sortedFilelist[i]);
		selectWindow(sortedFilelist[i]);

		// go to middle of stack (auto-threshold selection works best when in centre)
		getDimensions(width, height, channels, slices, frames);
		halfPos = round(slices / 2);
		setSlice(halfPos);
		run("Enhance Contrast", "saturated=0.35");
		
		// convert to 8-bit
		run("8-bit");
		
		// function to smoothen image and remove background
		preprocessing(sortedFilelist[i]); 
		wait(2000);
		
		// call functions for segmentation - after testing, you can comment out what you don't need
		SimpleSeg(sortedFilelist[i]);
		wait(2000);
		
		Hysterisis(sortedFilelist[i]);
		wait(2000);
		
		Otsu(sortedFilelist[i]);
		wait(2000);
		
		Moments(sortedFilelist[i]);
		wait(2000);
		
		Percentile(sortedFilelist[i]);
		wait(2000);
		
		MaxEntropy(sortedFilelist[i]);
		wait(2000);
		
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

/////-- 3D image analysis suite
function SimpleSeg(title){
	//--3D simple segmentation
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	run("3D Simple Segmentation", "low_threshold=20 min_size=0 max_size=-1"); // parameters can be changed
	selectWindow("Seg");
	close();
	selectWindow("Bin");
	run("Invert", "stack");
	// need to make binary - ToDo
	saveAs("Tiff", outputFolder + "3DSimpleSeg_" + filelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_3DSimpleSeg20-0_" + filelist[i]);
	close("MAX_3DSimpleSeg20-0_" + filelist[i]);
	close("3DSimpleSeg_" + filelist[i]);
}

function Hysterisis(title) { 
	//-- hysterisis TH
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	run("3D Hysteresis Thresholding", "high=128 low=50 show labelling"); // low and high can be changed 
	selectWindow("Proc_Multi");
	
	run("Make Binary", "method=Default background=Default");
	saveAs("Tiff", outputFolder + "3DHyst_" + filelist[i]); 
	//run("Invert", "stack");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_3DHyst_" + filelist[i]);
	close("MAX_3DHyst128-50_" + filelist[i]);
	close("3DHyst_" + filelist[i]);
}


//////-- Fiji Global Auto Thresholding

function Otsu(title) { 
	//-- Otsu
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	setAutoThreshold("Otsu");
	//setThreshold(0, 20); // can be changed 
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Light");
	run("Invert", "stack");
	saveAs("Tiff", outputFolder + "Otsu_" + filelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_Otsu-_" + filelist[i]);
	close("MAX_Otsu-_" + filelist[i]);
	close("Otsu_" + filelist[i]);
}

function Moments(title) { 
	//-- Moments
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	setAutoThreshold("Moments");
	//setThreshold(0, 20); // can be changed 
	run("Convert to Mask", "method=Moments background=Light");
	run("Invert", "stack");
	saveAs("Tiff", outputFolder + "Moments_" + filelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_Moments_" + filelist[i]);
	close("MAX_Moments_" + filelist[i]);
	close("Moments_" + filelist[i]);
}

function Percentile(title) {
	//-- Percentile
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	setAutoThreshold("Percentile");
	//setThreshold(0, 15); // can be changed 
	run("Convert to Mask", "method=Percentile background=Light");
	run("Invert", "stack");
	saveAs("Tiff", outputFolder + "Perc_" + filelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_Perc_" + filelist[i]);
	close("MAX_Perc_" + filelist[i]);
	close("Perc_" + filelist[i]);
}
	
function MaxEntropy(title) {
	//-- MaxEntropy
	selectWindow(filelist[i]);
	run("Duplicate...", "title=Proc duplicate");
	selectWindow("Proc");
	setAutoThreshold("MaxEntropy");
	//setThreshold(0, 30); // can be changed 
	run("Convert to Mask", "method=MaxEntropy background=Light");
	run("Invert", "stack");
	saveAs("Tiff", outputFolder + "MaxEntro_" + filelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", outputFolderMIPs + "MAX_MaxEntro_" + filelist[i]);
	close("MaxEntro_" + filelist[i]);
	close("MAX_MaxEntro_" + filelist[i]);
}