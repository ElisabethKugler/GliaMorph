/* Macro to test code version by comparison of segmented images
 * Author: Elisabeth Kugler 2021
 * contact: kugler.elisabeth@gmail.com

Input: segmented data
Funtion: compares images from original and adapted code folders
End: close all open windows and examine output in folder "out"

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

///// prompt user to select input folders
pathO = getDirectory("Input Folder Original"); 
filelistO = getFileList(pathO); 
sortedFilelistO = Array.sort(filelistO);

pathA = getDirectory("Input Folder Adapted"); 
filelistA = getFileList(pathA); 
sortedFilelistA = Array.sort(filelistA);

///// create output folders and file
// EDMs for thickness measurements
dir = File.getParent(pathO);
OutputDir = dir + "/out-OrigToTHEdges/"; 
File.makeDirectory(OutputDir);

f = File.open(OutputDir + "OverlapResults.txt");
print(f, "FileName" + "\t" + "Total Overlap" + "\t" + "Jaccard Index" + "\t" + "Dice Coefficient");


// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

// set colours and measurements
setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);
run("Set Measurements...", "area mean standard min centroid center perimeter bounding fit integrated area_fraction stack redirect=None decimal=3");


for (i=0; i< sortedFilelistO.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelistO[i], ".tif")) {
	// show rogress
	k = i; // set number for adapated before i++ counter increases as it would otherwise open next one up
	// problem was that "out" folder was created in "orig" input folder - that increased the number of objects in folder 
	// and thus counter was thrown off

	open(pathO + sortedFilelistO[i]);
	run("16-bit");

	// get short file name without tif for file selection hen saving MorpholibJ results
	imgName = getTitle();
	shortimgName = replace(imgName, ".tif", "");
	
	// open adapted image with similar name	
	open(pathA + sortedFilelistA[k]); // counter increases and opens second one
	run("16-bit");
	run("Invert", "stack"); // if TH compared to orig
	
	LegacyTesting(sortedFilelistO[i],sortedFilelistA[k]);
	close("*");
	}
}
close("*");
run("Close All");
run("Collect Garbage");

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

showMessage("Macro is finished"); // show message when Macro is finished
// .. Macro finished .. // 


function LegacyTesting(orig,adap) { 
// function description
	
	
	// Quantify Label Overlap measure - requires MorpholibJ > update: IJPB-plugins
//	o = replace(sortedFilelistO[i], ".tif", "");     
//	a = replace(sortedFilelistA[i], ".tif", "");     
	run("Label Overlap Measures", "source=[" + sortedFilelistO[i] + "] target=[" + sortedFilelistA[k] + "] overlap jaccard dice");
	

	close(shortimgName + "-individual-labels-overlap-measurements"); // close results with slice-by-slice results
	selectWindow(shortimgName + "-all-labels-overlap-measurements"); // select window with overall results
	TO = getResult("TotalOverlap"); 			
	JI = getResult("JaccardIndex"); 	
	DC = getResult("DiceCoefficient"); 	
	print(f, shortimgName + "\t" + TO + "\t" + JI + "\t" + DC);

	saveAs("Results",  OutputDir + sortedFilelistO[i] + "_JacDicOv.csv");
	close(sortedFilelistO[i] + "_JacDicOv.csv"); // close results
	
	// Coloured overlap
	selectWindow(sortedFilelistO[i]);
	run("Green"); // original
	selectWindow(sortedFilelistA[k]);
	run("Invert", "stack"); // if TH compared to orig
	
	run("Magenta"); // adapted
	run("Merge Channels...", "c1=[" + sortedFilelistO[i] + "] c2=[" + sortedFilelistA[k] + "] create");
	
	saveAs("Tiff", OutputDir + "Overlap_" + sortedFilelistO[i]);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDir + "MAX_Overlap_" + sortedFilelistO[i]);

}