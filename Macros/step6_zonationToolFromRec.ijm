/* Analysis of zebrafish retina zonation based on intensity profiles
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

///// GUI for zonationTool analysis /////
Dialog.create("zonationTool selections");
choices = newArray("yes","no");
initialText = (" ");

Dialog.addChoice("Perform intensity plotting?", choices);
Dialog.addChoice("Perform scale normalization?", choices);
Dialog.addNumber("Output image width [px]:", 1920);
Dialog.addNumber("Height of Sigma added with rotationTool [um]:", 10);
Dialog.addString("InputFolder", initialText);

// create dialog
Dialog.show();

// parse choices and input
IntPlot = Dialog.getChoice(); 
ImgNorm = Dialog.getChoice(); 
ImgDim = Dialog.getNumber();
sigma = Dialog.getNumber();  // "var name additionalbelow in rotationTool"
path = Dialog.getString();

setForegroundColor(0, 0, 0); 
setBackgroundColor(255, 255, 255);

run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

if (IntPlot==choices[0]){ // yes
	///// Directories and folders
//	path = getDirectory("Input Folder");
	filelist = getFileList(path);
	sortedFilelist = Array.sort(filelist);
	
	ZonationToolDir = path + "/ZonationTool/"; 
	File.makeDirectory(ZonationToolDir);
	
	f = File.open(ZonationToolDir + "ZonationResults.txt");
	print(f, "Filename" + " \t"  + "ImageHeight" + " \t" + "LengthOfROI_HeightWOSigma");

	setBatchMode(true); //batch mode on
	print("Input Directory: " + path);

	counter = 0;
	
	//iterate through input directory
	for (i=0; i< sortedFilelist.length; i++) {
		if (endsWith(sortedFilelist[i], ".tif")) {
			open(path + sortedFilelist[i]);
			selectWindow(sortedFilelist[i]);
			img=getTitle();
			shortTitle = replace(img, ".tif", "");
			column_label = img;

			getDimensions(width, height, channels, slices, frames);
			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			fixedWidthEnd = height;
	//		imageWidth = width * pixelWidth; 
	//		imageWidthwoSigma = imageWidth - sigma;

			imageHeight = height * pixelHeight; 
			imageHeightwoSigma = imageHeight - sigma;
			

			print(f, img + " \t"  + imageHeight + " \t" + imageHeightwoSigma);
			
			// 05032021 pre-processing test to improve quality
			// z-dimension bleach/intensity correction
			run("Bleach Correction", "correction=[Simple Ratio] background=0");
			selectWindow("DUP_" + img);
			rename(img);
			// CLAHE
			run("Enhance Contrast...", "saturated=0.3 normalize process_all");
					
			plotIntensity(sortedFilelist[i]);
			
			wait(1000);
	
			counter++;
		}
	}
wait(1000);
close("*");
}else{
	print("Zonation analysis not selected.");
}

close("Results");
print("Output Directory: " + ZonationToolDir);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

run("Close All");
showMessage("Macro is finished"); 


///// FUNCTIONS
function plotIntensity(title) { 
// function description

///// dimensionality reduction ///// 
	run("8-bit");
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);

	BlurFactor = round(height / 40); // 13122021
	
	// reduce in z-axis
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Tiff", ZonationToolDir + "IntermZonation_" + img); // 1D representation of 3D data; intensity showing distribution of lamination
	wait(1000);
	close("IntermZonation_" + img);
	open(ZonationToolDir + "IntermZonation_" + img);
	
	// reduce in x-axis
	run("Reslice [/]...", "output=1.000 start=Left");
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.35");
	run("Fire");
	saveAs("Tiff", ZonationToolDir + "Zonation_" + img); // 1D representation of 3D data; intensity showing distribution of lamination

	run("Gaussian Blur...", "sigma=" + BlurFactor);
	// scale image width to 1920 - so different profiles are comparable -- 17112020
	if (ImgNorm==choices[0]){ // yes
		run("Scale...", "x=- y=- width=" + ImgDim + " height=6 interpolation=Bilinear average create");
		lineLength = ImgDim;
	}else {
		lineLength = fixedWidthEnd;
	}
	
	///// intensity profile ///// 
	setTool("line");
	makeLine(0, 0, lineLength, 0); // work on normalization  -- 
	profile = getProfile(); 
	
	for (i=0; i<profile.length; i++){ // from https://imagej.nih.gov/ij/macros/StackProfileData.txt
	    setResult(column_label, i, profile[i]);
	}
	updateResults();
	saveAs("Results", ZonationToolDir + "ZonationToolProfiles.csv");
	

}
