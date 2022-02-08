/* Semi-automatic ROI selection tool within stack with ROI within stack
 * this Macro uses multiple ROIs per image 
 * >> this allows multiple clones to be extracted from one image
 * 
 * To setup: needs update site "ROI-group"
 * then draw multiple ROIs > Select > Properties (1,2,.. N) [integers]

 * Author: Elisabeth Kugler 2021
 * contact: kugler.elisabeth@gmail.com

BSD 3-Clause License

Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom]
All rights reserved.

GNU General Public License v2.0
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


// GUI to get output image dimensions
Dialog.create("subregionTool - Output Dimensions");
Dialog.addNumber("Output image width [um]:", 60); 
Dialog.addNumber("Output image depth [um]:", 15); 
Dialog.addNumber("Select sigma size for vessels [um]:", 10);
// create dialog
Dialog.show();

// parse output dimensions
xySize = Dialog.getNumber(); // micrometer x,y width - can be changed
zDepth = Dialog.getNumber(); // micrometers z-stack depth - can be changed
additionBelow = Dialog.getNumber(); // sigma to be attached below to include vessels

// get middle position of stack - needed to measure box sizes
xySizeHalf = round(xySize / 2); // do not change! 

// set measurements for retinaHeight
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// prompt user to select input folder 
path = getDirectory("Input Folder"); 
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);

//setBatchMode(true); //batch mode on

print("Input Directory: " + path);

roiManager("Open", path + "RoiSetLine.zip");
n = roiManager("count");
var r=0; // counter for RoiSetLine
var currentGroup = 1; // counter for ROIGroups - to increment with each image

// initialize z pos measurement
var MeasZPos = 0; // which slice the ROI is placed at

//// --  create output folders
// xyDir
xyDir = path + "/xyDir/"; 							
File.makeDirectory(xyDir);
xyDirMIPs = xyDir + "/xyDirMIPs/"; 							
File.makeDirectory(xyDirMIPs);
// zDir
zDir = path + "/zDir/"; 							
File.makeDirectory(zDir);
zDirMIPs = zDir + "/zDirMIPs/"; 						
File.makeDirectory(zDirMIPs);

// create file for output measurements of retina height 
f = File.open(path + "RetinaHeight.txt");
print(f, "Filename" + " \t"  + "RetinaHeight");

///// iterate through images in the folder calling xyReduction and zReduction functions
for (i=0; i< sortedFilelist.length; i++) {   
	if (endsWith(sortedFilelist[i], ".tif")) {
	
		roiC=0; // counter for ROIs - restart counter every time when new image is opened

		open(path + sortedFilelist[i]);
		// show rogress
		showProgress(i+1, sortedFilelist.length);
		print("processing ... " + sortedFilelist[i]);
		meep = getTitle();
		short = replace(meep, ".tif", "");

		selectWindow(sortedFilelist[i]);
		
		xyReduction(sortedFilelist[i]); // call fct to reduce data in xy

		currentGroup++; // increment with each image
		close("*");
	}
}
run("Close All");

print("Output Directory: " + zDir);

run("Collect Garbage");
setBatchMode(false); //exit batch mode


// show message when Macro is finished
showMessage("Macro is finished"); 


///// xyReduction function 
function xyReduction(title) { 
//get image properties
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);

	// Establish list of groups indexes
	for (roi = 0; roi < roiManager("Count"); roi++){
		roiManager("Select", roi);	
		groupOfRoi = Roi.getGroup();
	//	RoiGroups = Array.concat(RoiGroups, groupOfRoi);
		if (groupOfRoi == currentGroup){
	        // the ROI belongs to the current group, do something
	        // otherwise dont do anything ie skip it
	        print(currentGroup);
	        selectWindow(sortedFilelist[i]);
			run("Duplicate...", "title=ForSRs duplicate");

			roiManager("Select", r);	// make sure to select ROI again	
			run("Measure"); // measure the angle of line ROI for rotation
		
			MeasAngle = getResult("Angle"); // measured angle from LineROI
		
			// DO SOMETHING
				
			// save as tiff "xy-reduced_"
			saveAs("Tiff", xyDir + "xy-reduced_" + short + roiC); 
		
			// make and save MIP
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Jpeg", xyDirMIPs + "MIPxy-reduced_" + short + roiC); 
			close();
			
			selectWindow("xy-reduced_" + short + roiC + ".tif");
		 
			zReduction(sortedFilelist[i]); // moved this here for multiple ROIs in the same image

			
			roiC++;
			r++; // counter for ROI in ROIset -- moved this here for multiple ROIs in the same image
		}
	}	
}


///// zReduction function
function zReduction(title) { 
	// DO SOMETHING
	saveAs("Tiff", zDir + "z-reduced_" + short + roiC); 

	// make and save MIP
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", zDirMIPs + "MIPz-reduced_" + short + roiC); 
	
}

