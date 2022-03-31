/* Quantification of MG features in segmented images
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

///// prompt user to select input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// create output folders and file

// Centrelines for skeleton analysis and thickness
OutputDirSkel = path + "/outSkel/"; 

// Zonation output
outZone = path + "/outZone/"; 

print("Input Directory: " + path); // which input directory was selected

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

// set colours and measurements
setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);
run("Set Measurements...", "area mean standard min centroid center perimeter bounding fit integrated area_fraction stack redirect=None decimal=3");

// global vars
var imgName="";
var shortTitle = "";
var column_label = "";
var halfPos = 10;


counter = 0;
for (j=0; j< sortedFilelist.length; j++) {
	if (endsWith(sortedFilelist[j], ".tif")) {
		// open TH image
		open(path + sortedFilelist[j]);
		
		imgName=getTitle();
		shortTitle = replace(imgName, ".tif", "");
		column_label = imgName;
		
		// plot texture segmented/TH image
		wait(8000);
		plotIntensity(sortedFilelist[j], outZone, "Average", "Average"); // filename, inputFolder, outputFolder
		
		// plot texture of skeletonized image	
		open(OutputDirSkel + "Skel_" + sortedFilelist[j]);
		wait(8000);
		selectWindow("Skel_" + sortedFilelist[j]);
		plotIntensity("Skel_" + sortedFilelist[j], OutputDirSkel, "Max", "Average"); // filename, inputFolder, outputFolder
		close("*");
		
		counter++;
	}
}


run("Close All");

run("Collect Garbage");

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

showMessage("Macro is finished"); // show message when Macro is finished
// .. Macro finished .. // 


function plotIntensity(name, outName, Filter1, Filter2) { 
///// function to collapse 3D stack into 1D vector for texture analysis ///// 
	run("8-bit");
	
	// get img and vx dimensions
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
		
	// -- dimensionality reduction
	// reduce in z-axis
	run("Z Project...", "projection=[" + Filter1 + " Intensity]"); // need to be Avg not Max bc binary/TH image

	// uncomment the next 4 lines if working with resliced data
/*
	saveAs("Tiff", outName + "intermZonation_" + sortedFilelist[i]); 
	wait(1000);
	close("IntermZonation_" + sortedFilelist[i]); // close and open as reslicing can impact this 
	open(outName + "IntermZonation_" + sortedFilelist[i]);
*/
	
	// reduce in x-axis
	run("Reslice [/]...", "output=1.000 start=Left"); // reslice 2D-MIP to get 1D-vector
	run("Z Project...", "projection=[" + Filter2 + " Intensity]");
	run("Enhance Contrast", "saturated=0.35");
	run("Fire");
	saveAs("Tiff", outName + "Zonation_" + sortedFilelist[j]); // 1D representation of 3D data; intensity showing distribution of lamination

	// blur to smoothen 1D vector
	BlurFactor = height / 40; // this factor will be needed to smoothen data 
	run("Gaussian Blur...", "sigma=" + BlurFactor); // blur to smoothen 
	
	///// intensity profile ///// 
	lineLength = height; // this will be needed to plot profile along the entire image
	setTool("line");
	makeLine(0, 0, lineLength, 0); // could normalize them all to same size (see zonationTool)
	profile = getProfile(); 
	
	// write profile into Results table and save table
	for (j=0; j<profile.length; j++){ // from https://imagej.nih.gov/ij/macros/StackProfileData.txt
	    setResult(column_label, j, profile[j]);
	}
	updateResults();
	
	saveAs("Results", outName + "ZonationToolProfiles.csv");

	
}
