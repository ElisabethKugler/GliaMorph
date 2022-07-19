/* Macro to analyse Muller glia (MG) endfeet 
 * Author: Elisabeth Kugler 2021
 * Copyright 2021 Elisabeth Kugler
 * contact: kugler.elisabeth@gmail.com

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// input folder raw MGs
pathMGraw = getDirectory("Input Folder raw MG data"); 
filelistMGraw = getFileList(pathMGraw);
filelistMGs = Array.sort(filelistMGraw); // sort file list numerically (more than 9 images can be in the folder)


// output directory
OutDir = pathMGraw + "/OutputMGEndfeet/"; 
File.makeDirectory(OutDir);

// create output file for measurements
outFile = File.open(pathMGraw + "EndfeetCoverage.txt");
print(outFile, "file name" + "\t" + "frame" + "\t" + "AreaCov [um]" + "\t" + "Percentage [%]");		

// print input directories
print("Input Directory raw MGs: " + pathMGraw);

// set fore- and background colours
setForegroundColor(255, 255, 255); 
setBackgroundColor(0, 0, 0); 

// set measurements: needed for EC and MG endfeet extraction
run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// ---- open files and iterate through them, using EC images as guide
for (e=0; e< filelistMGs.length; e++) {
	if (endsWith(filelistMGs[e], ".tif")) {
		// open raw ECs image
		open(pathMGraw + filelistMGs[e]);
		selectImage(filelistMGs[e]);
	
		//get image properties
		getDimensions(width, height, channels, slices, frames);
		preChannels = channels;
		preSlices = slices;
		preFrames = frames;
		// get voxel properties
		getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
		prePixelWidth =pixelWidth;
		prePixelHeight = pixelHeight;
		preVoxelDepth = voxelDepth;
		
		halfPos = round(slices / 2); // find the centre of the stack - needed for TH
		
		// replace channel info "CX-" from file name ("CX-" from "splitChannelsTool")
	    name = getTitle();
	
		// call function to extract endfeet using 30um box from the bottom of the image
		EndfeetExtraction(filelistMGs[e]);
	
		//3D bleach correction to correct for intra-stack intensity variability
		run("Bleach Correction", "correction=[Simple Ratio] background=0");
		wait(1000);
	    selectWindow(name);
	    close(name);
	    selectWindow("DUP_" + name); // bleach corrected
	    rename("MGraw");
	    run("8-bit");
	
		// analyse Endfeet
		// > reslice > MIP > TH > Area and Percentage measurement
		run("Reslice [/]...", "output=" + preVoxelDepth + " start=Bottom");
		if (frames > 1){ // for timelapses
			run("Z Project...", "projection=[Max Intensity] all");	
		}else { // for single-time points
			run("Z Project...", "projection=[Max Intensity]");
		}
	
		// LUT gray to make image gray
		run("Grays");
		saveAs("Tiff", OutDir + "MAX_" + name);
		
		// smoothen and enhance before segmenting with Threshold
		run("Median...", "radius=2 stack");
		// local contrast enhancement
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
		
		// segmentation with Otsu Threshold
		run("Threshold...");
		setAutoThreshold("Otsu dark");
		setThreshold(40, 255); //  this can be changed
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Otsu background=Light calculate");
	
		run("Invert", "stack"); // it measures the white as MG endfeet
		saveAs("Tiff", OutDir + "MAX_TH_" + name);
	//	run("Invert", "stack"); 
		
		// for timelapse - need to iterate over the individual timepoints
		if (frames > 1){ // if more than one timeframe it is a timelapse
		// swap frame and slices to then iterate over slices
			slices= preFrames;
			frames = preSlices;
			
			// iterate over each frame
			for (f=1; f < slices; f++){ // need to start interation with 1 - as there is no 0 slice
				setSlice(f);
				
				// Analyse > Measure to derive area and %area
				run("Measure");
				AreaUm = getResult("Area");
				fract = getResult("%Area"); //	area_fraction  %Area
			
				CalcArea = (AreaUm*fract)/100; // calculate covered area
				// print measurements into output file
				print(outFile, name + "\t" + f + "\t" + CalcArea + "\t" + fract);				
			}	
		}else {
			// Analyse > Measure to derive area and %area
			run("Measure");
			AreaUm = getResult("Area");
			fract = getResult("%Area"); //	area_fraction  %Area
		
			CalcArea = (AreaUm*fract)/100; // calculate covered area
			// print measurements into output file
			print(outFile, name + "\t" + "1" + "\t" + CalcArea + "\t" + fract);		
		}
		run("Close All");
	}
}

// --- finishing and cleaning up the Macro
closeEverything(); // call function to close remaining open windows

print("Output Directory: " + OutDir); // print output directory

run("Collect Garbage"); // clean up

showMessage("Macro is finished"); // show message when finished

//--- function to extract ROI, using EC height and multiplyting this by 2
function EndfeetExtraction(title){
		// select 3D input stack
		selectWindow(name);
	
		// draw bounding box 30um
		HeightDoublePx = 30 / pixelHeight; // convert um to px
		StartHeight = height - HeightDoublePx; // bounding box starting position (image height minus ROI height)

		// apply bounding box to bleach-corrected MG raw data
		selectWindow(name);
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