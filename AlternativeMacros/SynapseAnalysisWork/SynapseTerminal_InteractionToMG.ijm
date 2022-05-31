/* Analysis of zebrafish IPL synapse terminal interaction with MG protrusions
 * EKugler March 2021
 * 
 * Author: Elisabeth Kugler 2020 - 2022
 * Copyright 2021 Elisabeth Kugler, UCL
 * contact: kugler.elisabeth@gmail.com
 
(a) will use ROIs from "SynapseTerminal_SegmentationAndFeatures.ijm" to extract IPL in the MG channel
(b) performs preprocessing and segmentation
(c) will perform synapse terminal and MG density analysis
(d) will perform synapse terminal and MG overlap analysis
(e) you can close all windows once you receive the message "Macro finished."

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// prompt for folder with segmented synapse terminals
pathIPL = getDirectory("Input Folder: OutputDirIPL from Synapse Terminal Segmentation"); 
filelistIPL = getFileList(pathIPL);
sortedFilelist = Array.sort(filelistIPL);

print("Input Directory Segmented Synapse Terminals: " + pathIPL);

// prompt for folder with raw MG
pathMG = getDirectory("Input Folder: Folder with raw MG data"); 
filelistMG = getFileList(pathMG);

print("Input Directory Raw MG Data: " + pathMG);

prefix = getString("Do the MG data have a prefix, e.g.: ", "C2-");


// output folder
OutputIx = pathIPL + "/OutputIx/"; 
File.makeDirectory(OutputIx);

// create output file for measurements
outFile = File.open(OutputIx + "OverlapMeasurements.txt");
print(outFile, "file name" + "\t" + "OverlapVol [um3]" + "\t" + "MGVol [um3]" + "\t" + "MG Density [%]" + "\t" + "SynVolume  [um3]" + "\t" + "Syn Density [%]" + "\t" + "M1-MG" + "\t" + "M2-Syn");	

setForegroundColor(255, 255, 255); 
setBackgroundColor(0, 0, 0); 

for (i=0; i< sortedFilelist.length; i++) {
		if (startsWith(sortedFilelist[i], "3DSegm_")) {
			// open segmented synapse terminals
			open(pathIPL + sortedFilelist[i]);
			selectWindow(sortedFilelist[i]);

			// get image dimensions
			getDimensions(width, height, channels, slices, frames);
			preChannels = channels;
			preSlices = slices;
			preFrames = frames;

			imageVox = width * height * slices;
			
			// get voxel dimensions
			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			prePixelWidth =pixelWidth;
			prePixelHeight = pixelHeight;
			preVoxelDepth = voxelDepth;

			voxVol = (pixelWidth * pixelHeight * voxelDepth);

			imageVol = imageVox * voxVol;
			
			// open MG with the same name as the synapse file
		    name = getTitle();
		    nameShort = substring(name,10,lengthOf(name)); // remove "3DSegm_C1-" from synapse terminal file
			
			// open MG files
			for (m=0; m< sortedFilelist.length; m++) {
					if (endsWith(sortedFilelist[m], nameShort)) {
						open(pathMG + prefix + nameShort);
						rename("MG");
					}
				}
			
			// title shortening for ROI
			selectWindow(sortedFilelist[i]);
		    nameShortROI = substring(name,7,lengthOf(name)); // "3DSegm_"

			// select MG window
			selectImage("MG"); 
		
			// open ROI 
			roiManager("Open", pathIPL + nameShortROI + ".roi");
			// crop MG to the correct IPL size, using ROIs from step7a_synapseTerminalSegmentationAndFeatures.ijm
			roiManager("Select", 0);
			run("Crop");
			
			saveAs("Tiff", OutputIx + "MGCrop_" + nameShort); 
			rename("MGCrop");
			
			roiManager("Select", 0);
			roiManager("Delete");
			
			// segment MG IPL protrusion
			selectImage("MGCrop"); 
			
			//----  segmentation of MG data			
			// bleach correction in z direction as there is a significant signal decay axially
			run("Bleach Correction", "correction=[Simple Ratio] background=0");
			selectWindow("DUP_MGCrop");
			run("8-bit");
			halfPos = round(slices / 2);
			setSlice(halfPos);

			run("3D Edge and Symmetry Filter", "alpha=0.500 compute_symmetry radius=10 normalization=10 scaling=2 improved");
			wait(5000);
		
			selectWindow("Symmetry_smoothed_10");
		// re-set original image values
			run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
			
			saveAs("Tiff", OutputIx + "preproc_" + sortedFilelist[i]); 
		
			setSlice(halfPos);
			// run("Enhance Contrast", "saturated=0.35");
			
			run("8-bit");
			run("Threshold...");
			setThreshold(4, 255);
			setOption("BlackBackground", false);
			run("Convert to Mask", "method=Otsu background=Dark");

			saveAs("Tiff", OutputIx + "MGSegm_" + nameShort); 
			rename("MGSegm");

			// select the segmented IPL synapse terminals and make that image binary
			selectWindow(name);
			run("8-bit");
			setSlice(10);
			setThreshold(1, 255);
			setOption("BlackBackground", false);
			run("Convert to Mask", "method=Otsu background=Dark");
			rename("Syn");

			// ---- measure overlap
			// use image calculator to find IPL synapse terminal and MG protrusion overlap
			// overlap analysis using imageCalculator
			imageCalculator("AND create stack", "Syn","MGSegm");
			selectWindow("Result of Syn");
			
			saveAs("Tiff", OutputIx + "ImgCalc_TH_" + nameShort); 
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Jpeg", OutputIx + "MAX_ImgCalc_TH_" + nameShort); 
			close();
			
// CALCULATE THE NUMBER OF SYNAPSES CONTACTED
			selectWindow("ImgCalc_TH_" + nameShort);
			rename("Result of Syn");
			run("3D Objects Counter", "threshold=128 slice=29 min.=5 max.=39140010 objects surfaces centroids centres_of_masses statistics summary");
			selectWindow("Statistics for Result of Syn");
			saveAs("Results", OutputIx + "3DObjCounter_" + nameShort + ".csv");

			// calculate M1 and M2
			// calculate voxels in image with overlap
			run("Histogram", "stack");
			Plot.getValues(values, counts);
			OverlapVox = counts[255]; // black 					
			close(); // histogram			
			OverlapVol = voxVol * OverlapVox; // voxel to volume [um]
			close("Result of Syn");
			
			// calculate voxels in segmented MG image
			selectImage("MGSegm");
			run("Histogram", "stack");
			Plot.getValues(values, counts);
			MGVox = counts[255]; // black 					
			close(); // histogram			
			MGVol = voxVol * MGVox; // voxel to volume [um]
			
			MGDen = (MGVol * 100) / imageVol;
			
			// calculate voxels in segmented EC image
			selectImage("Syn");
			run("Histogram", "stack");
			Plot.getValues(values, counts);
			SynVox = counts[255]; // black 					
			close(); // histogram			
			SynVol = voxVol * SynVox; // voxel to volume [um]
			
			SynDen = (SynVol * 100) / imageVol;
			
			// Manders Coefficient
			M1MG = OverlapVol/MGVol;
			M2Syn = OverlapVol/SynVol;


			print(outFile, nameShort + "\t" + OverlapVol + "\t" + MGVol + "\t" + MGDen + "\t" + SynVol + "\t" + SynDen + "\t" + M1MG + "\t" + M2Syn);		
			run("Close All");
		}
}

selectWindow("Log");
saveAs("Text", OutputIx + "3DObjCounter_analysisSummary.txt");

print("Output Directory: " + OutputIx);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// show message when Macro is finished
showMessage("Macro is finished"); 