/* Macro for czi to tiff conversion
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

run("Bio-Formats Macro Extensions");

setBatchMode(true); //batch mode on

///// prompt user to select input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// create output folder
OutputDir = path + "/tiff/"; 
File.makeDirectory(OutputDir);

OutputDirMIPs = OutputDir + "/MIPs/"; 
File.makeDirectory(OutputDirMIPs);

print("Input Directory: " + path);

///// open images from inputfolder
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".czi")) { // if lif files - change here

		dotIndex = indexOf(sortedFilelist[i], ".");
		name = substring(sortedFilelist[i], 0, dotIndex);
		
		// show progress
		showProgress(i+1, sortedFilelist.length);
		print("processing ... " + sortedFilelist[i]);
	
		Ext.setId(path+sortedFilelist[i]);
		Ext.getSeriesCount(seriesCount); //-- Gets the number of image series in the active dataset
	
		for (j=1; j<=seriesCount; j++) {
			
			print("series " + j);
			// czi import using Bioformats
			run("Bio-Formats Importer", "open=[" + path + sortedFilelist[i] + "] autoscale color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+j);

			// Save as tiff stack
			//sortedfilelist[i] = replace(sortedFilelist[i], "\\.czi", "");
			saveAs("Tiff", OutputDir + name + "_series_" + j);
			rename("img");
				
			// create maximum intensity projections (MIPs)
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Tiff", OutputDirMIPs + "MAX_" + name + "_series_" + j);
		
			// make composite to show all colours in jpeg MIP
			getDimensions(width, height, channels, slices, frames);
			if (channels != 1) {
				run("Channels Tool...");
				Stack.setDisplayMode("composite");
			}
					
			// save MIP
			run("Enhance Contrast", "saturated=0.35");
			saveAs("Jpeg", OutputDirMIPs + "MAX_j_" + name + "_series_" + j);
			close(); 
			
			// close tiff stack
			selectWindow("img");
			close();
		}
	}
}

run("Close All");

print("Output Directory: " + OutputDir);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// show message when Macro is finished
showMessage("Macro is finished"); 