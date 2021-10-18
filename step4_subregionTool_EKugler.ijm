/* Semi-automatic ROI selection tool with ROI selection from MIP 
 * Author: Elisabeth Kugler 2020
 * contact: kugler.elisabeth@gmail.com

BSD 3-Clause License

Copyright (c) [2021], [Elisabeth C. Kugler, University College London, United Kingdom]
All rights reserved.

(1) prompt for input folder
(2) prompt for RoiSetLine.zip
(3) rotation to align image along y-axis (might require 90degreeRotationTool first - see documentation)
(4) performs x-y reduction
(5) performs reduction in z 

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
Dialog.addNumber("Output image depth [um]:", 10); 
Dialog.addNumber("Select sigma size for vessels [um]:", 10);
// create dialog
Dialog.show();

// parse output dimensions
xySize = Dialog.getNumber(); // micrometer x,y width - can be changed
zDepth = Dialog.getNumber(); // micrometers z-stack depth - can be changed
additionBelow = Dialog.getNumber(); // sigma to be attached below to include vessels
xySizeHalf = xySize / 2; // do not change!

// set measurements for retinaHeight
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// prompt user to select input folder 
path = getDirectory("Input Folder"); 
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);

setBatchMode(true); //batch mode on

print("Input Directory: " + path);

//open ROI set 
roiManager("Open", path + "RoiSetLine.zip");
n = roiManager("count");
r=0; // counter for RoiSetLine


// create output folders
xyDir = path + "/xyDir/"; 							// output folder
File.makeDirectory(xyDir);
zDir = path + "/zDir/"; 							// output folder
File.makeDirectory(zDir);
zDirMIPs = zDir + "/zDirMIPs/"; 							// output folder
File.makeDirectory(zDirMIPs);

// create file for output measurements of retina height 
f = File.open(path + "RetinaHeight.txt");
print(f, "Filename" + " \t"  + "RetinaHeight");

///// iterate through images in the folder calling xyReduction and zReduction functions
for (i=0; i< sortedFilelist.length; i++) {   
	if (endsWith(sortedFilelist[i], ".tif")) {
		open(path + sortedFilelist[i]);
		// show rogress
		showProgress(i+1, sortedFilelist.length);
		print("processing ... " + sortedFilelist[i]);
	
		selectWindow(sortedFilelist[i]);
		
		xyReduction(sortedFilelist[i]);
		zReduction(sortedFilelist[i]);

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
// function will align images along Y-axis using the measured angle from manual ROI
// then creates a bounding box (checking that dimensions fit)
// then crops image in x and y
function xyReduction(title) { 
//get image properties
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
	roiManager("Select", r);	
		
	run("Measure"); // measure the angle of line ROI for rotation

	MeasAngle = getResult("Angle"); // measured angle from LineROI

	///// 1 bottom right quadrant (0 to -90)
	if (MeasAngle <= 0 && MeasAngle >= -90){
	 	betrag = abs(MeasAngle);
		// rotate to 0 
		rot01 = -(0 + betrag);
		run("Rotate... ", "angle=" + rot01 + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs
		// -> then rotate -90 to align in y
		run("Rotate 90 Degrees Left");
		rot = rot01 - 90;
			
			
	///// 2 bottom left quadrant (-90 to -180)
	}else if (MeasAngle <= -90 && MeasAngle >= -180){ 
		// rotate to -180 -> then +90 
		betrag = abs(MeasAngle);
		rot01 = (-180 - betrag);
		run("Rotate... ", "angle=" + rot01 + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs
		// -> then rotate 90 to align in y
		run("Rotate 90 Degrees Right");
		rot = rot01 + 90;
			
	///// 3 top left quadrant (180 to 90)	
	}else if (MeasAngle <= 180 && MeasAngle >= 90){ 
		// rotate to 90
		betrag = abs(MeasAngle);
		rot = -(90 - betrag);
		run("Rotate... ", "angle=" + rot + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs
		
	///// 4 top right quadrant (90 to 0)	
	}else{
		// rotate to 90
		betrag = abs(MeasAngle);
		rot = -(90 - betrag);
		run("Rotate... ", "angle=" + rot + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs
	}
		
//	saveAs("Tiff", xyDir + "rot_" + filelist[i]); 
	selectWindow("Results"); // close RoiSetLine results table
	run("Close");
		
///// Bounding Box /////
	// rotate line ROI
	roiManager("Select", r);
	run("Rotate...", "rotate angle=" + rot);
	roiManager("Update");
		
	run("Measure"); // measure the angle of line ROI for splitting L R box
	
	// calculate box with and check image is wide enough
	MeasXum = getResult("BX"); // measured X-position from LineROI as centrepoint
	MeasX = MeasXum / pixelWidth; // vx
	
	MeasYum = getResult("BY"); // measured X-position from LineROI as centrepoint
	MeasY = MeasYum / pixelHeight; // vx == omege
	
	MeasLengthum = getResult("Length"); // measured length of line ROI after Rotation
	MeasLength = MeasLengthum / pixelHeight; // vx
	sigma = additionBelow / pixelHeight; // is the additional length added at the bottom for EC analysis

	remainingImg = (height - MeasY) + MeasLength;

	print(f, title + " \t" + MeasLengthum);

	// check for length of box in vx
	if (remainingImg >= sigma){
		BoxHeight = MeasLength + sigma;
	}else{
		BoxHeight = MeasLength;
	}
		
		
	// work with px not um
	widthUM = width * pixelWidth;
	// check box sizes
	B = width - MeasX;		// how much space there is to the right
	A = width - B;
	// make box 60um wide
	boxHalfWidth = round(xySizeHalf / pixelWidth);
	TotalBoxWidth = round(2 * boxHalfWidth);
	
	if (B >= boxHalfWidth){ // box fits right
		if (A >= boxHalfWidth) { // box fits left
			LStart = MeasX - boxHalfWidth;		
		}else{ // box does not fit to the left
			LStart = 0;  // start at the very left
		}
	}else{ // box does not fit to the right
		LStart = width - TotalBoxWidth;
	}

	selectWindow("Results"); // close RoiSetLine results table
	run("Close");
	r++; // counter for ROI in ROIset

	// make box
	setTool("rectangle");	
	makeRectangle(LStart, MeasY, TotalBoxWidth, BoxHeight); // x,y,w,h
	run("Crop");
		
//	// save as tiff "xy-reduced_"
	saveAs("Tiff", xyDir + "xy-reduced_" + filelist[i]); 
}


///// zReduction function
// function reduces stack in the z-dimension
function zReduction(title) { 
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
	
	NrSlices10umThick = zDepth / voxelDepth;
	// z-depth correction
	if (NrSlices10umThick <= slices) {
		SubStackSlices = round(NrSlices10umThick);
	}else{
		SubStackSlices = slices;
		print(filelist[i] + "not enough slices for substack");
	}
	
	if (channels == 1) {
		run("Make Substack...", "  slices=1-" + SubStackSlices);
	}else{
		run("Make Substack...", "channels=1-" + channels + " slices=1-" + SubStackSlices);			
	}
	saveAs("Tiff", zDir + "z-reduced_" + filelist[i]); 

	// make and save MIP
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.35");
	run("Enhance Contrast", "saturated=0.35");
	run("Fire");
	saveAs("Jpeg", zDirMIPs + "MIPz-reduced_" + filelist[i]); 
	
}

