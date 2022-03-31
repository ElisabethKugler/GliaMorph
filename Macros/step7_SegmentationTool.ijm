/* Segmentation of MG cells from pre-processed images
 * Author: Elisabeth Kugler 2021
 * contact: kugler.elisabeth@gmail.com

Caveat: 
 * This segmentation was optimized for Tg(TP1bglob:VenusPest)s940 and Tg(TP1bglob:CAAX-GFP).
 * see manuscripts for details

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

///// create output folder
OutputDir = path + "/TH/"; 
File.makeDirectory(OutputDir);

OutputDirMIPs = OutputDir + "/MIPs/"; 
File.makeDirectory(OutputDirMIPs);

print("Input Directory: " + path);

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);

///// open images from inputfolder
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".tif")) {
	// show progress
	showProgress(i+1, sortedFilelist.length);
	print("processing ... " + sortedFilelist[i]);

	open(path + sortedFilelist[i]);
	rename("img");

	getDimensions(width, height, channels, slices, frames);
	halfPos = round(slices / 2);
	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");
	run("8-bit");

	// bleach correction in z direction as there is significant signal decay axially w confocal images
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	selectWindow("DUP_" + "img");
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

	call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
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

	close("*");

	}
}

run("Close All");

print("Output Directory: " + OutputDir);

run("Collect Garbage");

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

// show message when Macro is finished
showMessage("Macro is finished"); 