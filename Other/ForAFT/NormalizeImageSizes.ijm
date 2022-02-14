/* 
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

setBatchMode(true); //batch mode on


///// prompt user to select input folder
path = getDirectory("Input Folder"); 
//path = "D:/Data Recovery/Xhuljana/kdrl_mCherry_TP1_CAAXGFP/Rep5/120hpf/tiff/zDir/2CDir/MIPs/";
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);


// GUI to select number of channels
Dialog.create("Image Output Height");
Dialog.addNumber("Image Output Height:", 1920);
// create dialog
Dialog.show();

// parse number
maxHeight = Dialog.getNumber(); 


// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

///// create output folder
OutputDir = path + "/Normalized/"; 
File.makeDirectory(OutputDir);

print("Input Directory: " + path);


//// open images from inputfolder
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".tif")) {

		open(path + sortedFilelist[i]);
		// Preprocess
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
		run("Subtract Background...", "rolling=100");
		run("Enhance Contrast", "saturated=0.35");
				
		// get all their heights and widths
		getDimensions(width, height, channels, slices, frames);
		// make ALL images the same height by top alignment and adding black padding at the bottom
		run("Canvas Size...", "width=" + width + " height=" + maxHeight + " position=Top-Center zero");
	
		// make 8-bit -- that's needed for an AFT filter later on
		run("8-bit");
		saveAs("Tiff", OutputDir + "Norm_" + sortedFilelist[i]);
		
		// Normalize(sortedFilelist[i]);
	}
}

run("Close All");

print("Output Directory: " + OutputDir);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

// show message when Macro is finished
showMessage("Macro is finished"); 
