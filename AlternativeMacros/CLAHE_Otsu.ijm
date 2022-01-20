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

setBatchMode(true); //batch mode on

///// prompt for input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// output folders
OutputDir = path + "/CLAHE_Otsu/"; 
File.makeDirectory(OutputDir);
OutputDirMIPs = path + "/CLAHE_Otsu/MIP/"; 
File.makeDirectory(OutputDirMIPs);

// set colours
setForegroundColor(0, 0, 0); 
setBackgroundColor(255, 255, 255);


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
	CLAHE_Otsu(sortedFilelist[i]);
	close("*");
	}
}

run("Close All");
run("Collect Garbage");

showMessage("Macro is finished"); // show message when Macro is finished
// .. Macro finished .. // 

///// FUNCTIONS /////
function CLAHE_Otsu(title) { 
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


	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");

	// bleach correction in z direction as there is significant signal decay axially w confocal images
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	//selectWindow("DUP_" + "img");
	// pre-processing
	run("8-bit");
	wait(2000);
	run("Median 3D...", "x=2 y=2 z=2");
	wait(2000);
	
	// segmentation
	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");
	wait(1000);
	run("Threshold...");
	setAutoThreshold("Triangle dark stack");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");

	// need some surface smoothing	
	run("Median 3D...", "x=2 y=2 z=2");
	wait(2000);
	run("Make Binary", "method=Default background=Default");
	
	// save segmented images
	saveAs("Tiff", OutputDir + "TH_" + sortedFilelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPs + "MAX_TH_" + sortedFilelist[i]); 
	close();
}
	