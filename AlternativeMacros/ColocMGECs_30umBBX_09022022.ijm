/* Macro to analyse Muller glia (MG) endfeet overlap to endothelial cells (ECs)
 * Author: Elisabeth Kugler 2021
 * Copyright 2021 Elisabeth Kugler
 * contact: kugler.elisabeth@gmail.com

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// ---- prompt user to select input folders for raw ECs, raw MGs, and segmented MGs
// input folder raw ECs
pathECs = getDirectory("Input Folder ECs"); 
filelistECsRaw = getFileList(pathECs);
filelistECs = Array.sort(filelistECsRaw); // sort file list numerically (more than 9 images can be in the folder)

// input folder raw MGs
pathMGraw = getDirectory("Input Folder raw MG data"); 
filelistMGraw = getFileList(pathMGraw);

// output directory
ECOutDir = pathECs + "/ECOutput/"; 
File.makeDirectory(ECOutDir);

// create output file for measurements
outFile = File.open(ECOutDir + "OverlapsMeasurements.txt");
print(outFile, "file name" + "\t" + "OverlapVol" + "\t" + "MGVol" + "\t" + "ECVol" + "\t" + "M1MG" + "\t" + "M2EC" + "\t" + "OverlapInterface" + "\t" + "AreaCov [um]");		

// print input directories
print("Input Directory raw ECs: " + pathECs);
print("Input Directory raw MGs: " + pathMGraw);

// set fore- and background colours
setForegroundColor(255, 255, 255); 
setBackgroundColor(0, 0, 0); 

// set measurements: needed for EC and MG endfeet extraction
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// ---- open files and iterate through them, using EC images as guide
for (e=0; e< filelistECs.length; e++) {
	if (endsWith(filelistECs[e], ".tif")) {
	// open raw ECs image
	open(pathECs + filelistECs[e]);
	selectImage(filelistECs[e]);

getDimensions(width, height, channels, slices, frames);
getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);


	
	// replace channel info "CX-" from file name ("CX-" from "splitChannelsTool")
    name = getTitle();
    rename(substring(name,3,lengthOf(name)));
    nameShort = getTitle();

	//3D bleach correction to correct for intra-stack intensity variability
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	wait(1000);
    selectWindow(nameShort);
    close(nameShort);
    selectWindow("DUP_" + nameShort); // bleach corrected
    rename("ECraw");

	// get voxel dimensions
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
	voxVol = (pixelWidth * pixelHeight * voxelDepth);
	voxSurf = (pixelWidth * voxelDepth);
	// get image dimensions
	getDimensions(width, height, channels, slices, frames);
	HalfStack = round(slices / 2); // find the centre of the stack - needed for TH

//--- open corresponding raw MG image - if endswith with same name as the EC raw image
	for (m=0; m< filelistMGraw.length; m++) {
		if (endsWith(filelistMGraw[m], nameShort)) {
			open(pathMGraw + filelistMGraw[m]);
			
			rename("MGraw");
			//3D bleach correction to correct for intra-stack intensity variability
			run("Bleach Correction", "correction=[Simple Ratio] background=0");
			wait(1000);
			selectWindow("MGraw");
			close();
			selectWindow("DUP_MGraw"); // bleach corrected
			rename("MGraw");
		}
	}
	
	selectWindow("ECraw");
	// call function to extract endfeet zone using EC information to draw a larger bounding box
	// use EC height -> multiply by 2
	ECandEndfeetExtraction(filelistECs[e]); 

	wait(2000);
	//---- analysis on raw data - intensity-based
	// overlap analysis using imageCalculator
	imageCalculator("AND create stack", "ECraw","MGraw");
	selectWindow("Result of ECraw");
	run("8-bit");
	
	// save
	saveAs("Tiff", ECOutDir + "ImgCalc_" + nameShort); 
	run("Z Project...", "projection=[Max Intensity]");
	run("Color Balance...");
	run("Enhance Contrast", "saturated=0.35");
	run("Fire");
	saveAs("Jpeg", ECOutDir + "MAX_ImgCalc_" + nameShort); 
	close();
	
	//---- analysis on segmented data - object-based overlap/co-occurence
	//--- ECs segmentation
	selectImage("ECraw");
	run("Duplicate...", "title=ECrawInterface duplicate");
	selectImage("ECraw");
	run("Subtract Background...", "rolling=50 stack");
	run("Gaussian Blur 3D...", "x=2 y=2 z=2");
	
	setSlice(HalfStack);
	run("Enhance Contrast...", "saturated=0.3");
	run("Enhance Contrast...", "saturated=0.3");
	run("8-bit");
	
	run("Threshold...");
	setThreshold(10, 255);
	//setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");
	// erosion to make it smaller after over-segmentation
	run("Erode (3D)", "iso=255");
	
	run("8-bit");
	
	//save
	saveAs("Tiff", ECOutDir + "EC_TH_" + nameShort); 
	rename("ECSegm");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "MAX_EC_TH_" + nameShort); 
	close();
	
	//--- MG segmentation of Endfeet
	selectImage("MGraw");
	run("Duplicate...", "title=MGrawInterface duplicate");
	selectImage("MGraw");
	run("Subtract Background...", "rolling=50 stack");
	run("Gaussian Blur 3D...", "x=2 y=2 z=2");
	
	setSlice(HalfStack);
	run("Enhance Contrast...", "saturated=0.3");
	run("Enhance Contrast...", "saturated=0.3");
	run("8-bit");

	run("Threshold...");
	setThreshold(10, 255);
	//setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");
	// erosion to make it smaller after over-segmentation
	run("Erode (3D)", "iso=255");
	run("8-bit");
	
	// save
	saveAs("Tiff", ECOutDir + "MG_TH_" + nameShort); 
	rename("MGSegm");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "MAX_MG_TH_" + nameShort); 
	close();
	
	//--- overlap analysis of thresholded images using imageCalculator
	imageCalculator("AND create stack", "ECSegm","MGSegm");
	selectWindow("Result of ECSegm");
	
	run("8-bit");
	// save
	saveAs("Tiff", ECOutDir + "ImgCalc_TH_" + nameShort); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "MAX_ImgCalc_TH_" + nameShort); 
	close();

	
	
	// calculate voxels in image with overlap
	selectWindow("ImgCalc_TH_" + nameShort);
	run("Histogram", "stack bins=256 x_min=0 x_max=255"); // here
	Plot.getValues(values, counts);
	OVoxVal1 = counts[0];
	OVoxVal2 = counts[255];
	if(OVoxVal1 < OVoxVal2){
		OverlapVox = OVoxVal1;
	}else{
		OverlapVox = OVoxVal2;
	}
								
	OverlapVol = voxVol * OverlapVox; // voxel to volume [um]
	
	close(); // histogram

	// quantify 2D surface
	run("Reslice [/]...", "output=" + voxelDepth + " start=Top");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "Surface2D_" + nameShort); 

	
	run("Measure");
	
	AreaUm = getResult("Area");
	fract = getResult("%Area"); //	area_fraction  %Area

	CalcArea = (AreaUm*fract)/100;

	
	
	// produce 1-voxel wide line of interaction surface
	selectWindow("ImgCalc_TH_" + nameShort);
	setOption("BlackBackground", false);
	run("Skeletonize", "stack");
	saveAs("Tiff", ECOutDir + "Interface_ImgCalc_TH_" + nameShort); 
	selectWindow("Interface_ImgCalc_TH_" + nameShort);
	rename("Interface");

	run("Histogram", "stack bins=256 x_min=0 x_max=255"); // here
	Plot.getValues(values, counts);

	InterVoxVal1 = counts[0];
	InterVoxVal2 = counts[255];
	if(InterVoxVal1 < InterVoxVal2){
		InterVox = InterVoxVal1;
	}else{
		InterVox = InterVoxVal2;
	}

	OverlapInterface = voxSurf * InterVox;
	close(); // histogram
	
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "MAX_Interface_ImgCalc_TH_" + nameShort); 
	close();

	// calculate voxels in segmented MG image
	selectImage("MGSegm");
	run("Histogram", "stack bins=256 x_min=0 x_max=255"); // here
	Plot.getValues(values, counts);

	MGVoxVal1 = counts[0];
	MGVoxVal2 = counts[255];
	if(MGVoxVal1 < MGVoxVal2){
		MGVox = MGVoxVal1;
	}else{
		MGVox = MGVoxVal2;
	}

	MGVol = voxVol * MGVox; // voxel to volume [um]
	close(); // histogram			
	
	// calculate voxels in segmented EC image
	selectImage("ECSegm");
	run("Histogram", "stack bins=256 x_min=0 x_max=255"); // here
	Plot.getValues(values, counts);

	ECVoxVal1 = counts[0];
	ECVoxVal2 = counts[255];
	if(ECVoxVal1 < ECVoxVal2){
		ECVox = ECVoxVal1;
	}else{
		ECVox = ECVoxVal2;
	}
	
	ECVol = voxVol * ECVox; // voxel to volume [um]
	close(); // histogram			
	
	// Manders Coefficient
	M1MG = OverlapVol/MGVol;
	M2EC = OverlapVol/ECVol;
	
	// MorpholibJ overlap measurement
	//run("Label Overlap Measures", "source=[ECSegm] target=[MGsegm] overlap volume false false_0");
	//MorphoOverlap = getResult("TargetOverlap");
	//MorphoVolSim = getResult("VolumeSimilarity");
	// FalseNeg = getResult("FalseNegativeError");
	// FalsePos = getResult("FalsePositiveError");
	selectImage("MGrawInterface");
	run("8-bit");
	run("Green");
	selectImage("ECrawInterface");
	run("8-bit");
	run("Magenta");
	selectImage("Interface");
	run("8-bit");
	run("Cyan");
	run("Merge Channels...", "c1=ECrawInterface c2=MGrawInterface c3=Interface create keep");
	saveAs("Tiff", ECOutDir + "Merged_" + nameShort); 
	run("Stack to RGB", "slices keep");
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", ECOutDir + "MAX_Merged_" + nameShort); 
	close();
	
	
	print(outFile, nameShort + "\t" + OverlapVol + "\t" + MGVol + "\t" + ECVol + "\t" + M1MG + "\t" + M2EC + "\t" + OverlapInterface + "\t" + CalcArea);		
	//print(outFile, nameShort + "\t" + OverlapVol + "\t" + MGVol + "\t" + ECVol + "\t" + M1MG + "\t" + M2EC + "\t" + MorphoVolSim);		
	// saveAs("Results",  RegDir + repMoving + "_Unregistered_JacDicOv.csv");
	
	run("Close All");
	}
}

// --- finishing and cleaning up the Macro
closeEverything(); // call function to close remaining open windows

print("Output Directory: " + ECOutDir); // print output directory

run("Collect Garbage"); // clean up

showMessage("Macro is finished"); // show message when finished

//--- function to extract ROI, using EC height and multiplyting this by 2
function ECandEndfeetExtraction(title){
		// select 3D stack
		selectWindow("ECraw");
	
		// draw bounding box 30um
		HeightDoublePx = 30 / pixelHeight; // convert um to px
		StartHeight = height - HeightDoublePx; // bounding box starting position (image height minus ROI height)
		// draw bounding box based on measurements
		setTool("rectangle");
		makeRectangle(0, StartHeight, width, HeightDoublePx); // x,y, width, height
		// crop bleach-corrected EC raw to the correct size
		run("Crop");

		// apply bounding box to bleach-corrected MG raw data
		selectWindow("MGraw");
		setTool("rectangle");
		makeRectangle(0, StartHeight, width, HeightDoublePx); // x,y, width, height
		run("Crop");
}

//--- function to close all remaining open windows
function closeEverything() { 
	if (isOpen("Results")) { // results table
		selectWindow("Results"); 
		run("Close");
	}
	if (isOpen("ROI Manager")) { // ROI manager from bounding box selection
		selectWindow("ROI Manager"); 
		run("Close");
	}
	if (isOpen("Threshold")) { // thresholding window
		selectWindow("Threshold"); 
		run("Close");
	}
	if (isOpen("Color")) { // adjust colour balance window
		selectWindow("Color"); 
		run("Close");
	}
}