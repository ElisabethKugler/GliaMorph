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
// EDMs for thickness measurements
OutputDirEDM = path + "/outEDM/"; 
File.makeDirectory(OutputDirEDM);
OutputDirEDMMIPs = OutputDirEDM + "/MIPs/"; 
File.makeDirectory(OutputDirEDMMIPs);

// Centrelines for skeleton analysis and thickness
OutputDirSkel = path + "/outSkel/"; 
File.makeDirectory(OutputDirSkel);
OutputDirSkelMIPs = OutputDirSkel + "/MIPs/"; 
File.makeDirectory(OutputDirSkelMIPs);

// Edges for Surface
OutputDirSurf = path + "/outSurf/"; 
File.makeDirectory(OutputDirSurf);
OutputDirSurfMIPs = OutputDirSurf + "/MIPs/"; 
File.makeDirectory(OutputDirSurfMIPs);

// Zonation output
outZone = path + "/outZone/"; 
File.makeDirectory(outZone);

// output file, saving measured parameters
fileOverview = File.open(path + "QuantificationResults.txt"); // display file open dialog
print(fileOverview, "name" + "\t" + "volume [um3]" + "\t" + "PercCov [%]" + "\t" + "SurfaceVol [um3]" + "\t" + "Thickness [um]");

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

///// open images from inputfolder for overall quantification, EDM, and skeletonization
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".tif")) {
	// show rogress
	showProgress(i+1, sortedFilelist.length);
	print("processing ... " + sortedFilelist[i]);

	open(path + sortedFilelist[i]);
	Quantification(sortedFilelist[i]); // call function quantification
	
	close("*");
	}
}

selectWindow("Skeleton Stats");
saveAs("Results", path + "Skeleton Stats.csv");
close("Results");


// 10012022 - try zonationTool TH and skel outside first for loop to see if that fixes issue with overwriting and actually appends zonationTool results
counter = 0;
for (j=0; j< sortedFilelist.length; j++) {
	// open TH image
	open(path + sortedFilelist[j]);
	
	imgName=getTitle();
	shortTitle = replace(imgName, ".tif", "");
	column_label = imgName;
	
	// plot texture segmented/TH image
	plotIntensity(sortedFilelist[j], outZone, "Average", "Average"); // filename, inputFolder, outputFolder
	
	// plot texture of skeletonized image	
	open(OutputDirSkel + "Skel_" + sortedFilelist[j]);
	selectWindow("Skel_" + sortedFilelist[j]);
	plotIntensity("Skel_" + sortedFilelist[j], OutputDirSkel, "Max", "Average"); // filename, inputFolder, outputFolder
	close("*");
	
	counter++;
}


run("Close All");

run("Collect Garbage");

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

showMessage("Macro is finished"); // show message when Macro is finished
// .. Macro finished .. // 



///// FUNCTIONS /////
function Quantification(title){
// This function quantifies volume, volume coverage, surface volume, and thickness;
// it also plots apicobasal texture of the segmented and skeletonized data calling the function "plotIntensity"

	//close("Results"); // test 06012022
	// plot texture segmented image
//	plotIntensity(sortedFilelist[i], outZone, "Average", "Average"); // filename, inputFolder, outputFolder
	//wait(1000);

	selectWindow(sortedFilelist[i]);
	rename("img");
	
	/////-- measure VOLUME using histogram and vox vol
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
	volVox = pixelWidth * pixelHeight * voxelDepth;

	run("Histogram", "stack");
	// [255] is MG Vox
	Plot.getValues(values, counts);
	MGVox = counts[255];
	close(); // histogram			
	MGVol = MGVox * volVox; 

	///// -- measure PERCENTAGE COVERAGE as object voxels in the image
	allVox = width * height * slices; // total Nr of vx in the image
	PercCov = (MGVox * 100) / allVox; // percentage of vx occupied by MG

	// surface smoothing
	run("Median 3D...", "x=6 y=6 z=6");
	wait(3000);
	run("Make Binary", "method=Default background=Default"); // binarize after smoothing

	// 3D EDM for thickness
	run("Duplicate...", "title=For3DEDM duplicate");
	selectWindow("For3DEDM");
	run("Geometry to Distance Map", "threshold=1");
	run("Green Fire Blue"); // assign LUT green-fire-blue
	// save
	saveAs("Tiff", OutputDirEDM + "EDM_" + sortedFilelist[i]);
	run("Z Project...", "projection=[Max Intensity]");
	run("Green Fire Blue"); // assign LUT green-fire-blue
	saveAs("Jpeg", OutputDirEDMMIPs + "MAX_EDM_" + sortedFilelist[i]);
	close("EDM_" + sortedFilelist[i]);

	
	///// - SKELETON-based
	// skeletonize entire img for network analysis
	selectWindow("img");
	run("Duplicate...", "title=ForSkel duplicate");
	selectWindow("ForSkel");

	// surface smoothing
	run("Gaussian Blur 3D...", "x=3 y=3 z=3");
	run("Make Binary", "method=Otsu background=Light"); // binarize after smoothing

	run("Skeletonize (2D/3D)");
	wait(3000);

	run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] prune_0");

	// save
	saveAs("Tiff", OutputDirSkel + "Skel_" + sortedFilelist[i]);	
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirSkelMIPs + "MAX_Skel_" + sortedFilelist[i]);

	// apicobasal texture analysis Skeleton
	selectWindow("Skel_" + sortedFilelist[i]);
	close("Results");
//	plotIntensity("Skel_" + sortedFilelist[i], OutputDirSkel, "Max", "Average"); // filename, inputFolder, outputFolder
//	wait(1000);
	
	selectWindow("Skel_" + sortedFilelist[i]);
	
	wait(5000);

	// summarize skeleton params
	run("Summarize Skeleton");
	SkelLength = getResult("Total length");
	junctions = getResult("# Junctions");
	EPs = getResult("# End-points");
	MaxBLength = getResult("Max branch length");
	MeanBLength = getResult("Mean branch length");

	wait(2000);

///// --- Code for thickness / dia from Kugler et al. ZVQ
// uses 3D EDM and skeleton to get 1-voxel-wise representation of thickness
// measurements not absolute as EDM is an approximation
	imageCalculator("AND create", "MAX_EDM_" + sortedFilelist[i],"MAX_Skel_" + sortedFilelist[i]);
	run("Fire");
	
	saveAs("Tiff", OutputDirSkelMIPs + "Thickness_" + sortedFilelist[i]);
	rename("LUTFire");
	
	close("MAX_Skel_" + sortedFilelist[i]);
	close("MAX_EDM_" + sortedFilelist[i]);
	
	/////// average diameter for whole 2D image - iterate through whole image in (x,y)
	counter = 0;
	value = 0;
	total = 0;
	avgLength = 0;
					
	selectWindow("LUTFire");
		
	// .. use image properties and brightness/intensity to quantify width at the respective vx in microns	
	for (y = 0; y < height; y++) {
		for (x = 0; x < width; x++) {
			properties = getPixel(x, y);
			if (properties != 0){ 		// skip if intensity value under 30-ish?
		 		counter++;
		 		total += properties; 							
		 	}
		}
	}
	average = (total/counter);  
	
	close("For3DEDM");
	close("ForSkel");

	//// -- SURFACE - uses edge detection and vox vol 
	selectWindow("img");
	run("Find Edges", "stack");

	// histogram count black 
	run("Histogram", "stack");
	// [255] is Surface Vox
	Plot.getValues(values, counts);
	surfaceVx = counts[255];
	// quantify surface vol using nr of vox and vox vol	
	surface = volVox * surfaceVx;

	// save edge/surface images
	selectWindow("img");
	saveAs("Tiff", OutputDirSurf + "Edges_" + sortedFilelist[i]);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirSurfMIPs + "MAX_Surface_" + sortedFilelist[i]);

	// print and save quantified params
	print(fileOverview, sortedFilelist[i] + "\t" + MGVol + "\t" + PercCov + "\t" + surface +"\t" + average);
	
}

// EK ToDo
function NucleiAnalysis(title){
	
}

function plotIntensity(title, outName, Filter1, Filter2) { 
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
