/* Macro for 90 degree rotation - optional before rotationTool
 * Author: Elisabeth Kugler 2020
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

///// GUI for rotation selection
Dialog.create("90DegreeRotationTool");
RotChoice = newArray("no","right (clockwise)", "left (anti-clockwise)");
Dialog.addChoice("Perform image rotation?", RotChoice);
// create dialog
Dialog.show();
// parse choice
RotC = Dialog.getChoice(); 

// prompt user to select input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);

// create outputfolder
outputFolder = path + "/90DegreeRotated/"; 
File.makeDirectory(outputFolder);

setBatchMode(true); //batch mode on
print("Input Directory: " + path);

run("Set Measurements...", "area mean standard min perimeter bounding fit area_fraction stack redirect=None decimal=3");

// iterate through images in folder, only selecting tif files
for (i=0; i< sortedFilelist.length; i++) {   
	if (endsWith(sortedFilelist[i], ".tif")) {
		open(path + sortedFilelist[i]);
		// show rogress
		print("processing ... " + sortedFilelist[i]);
			
		selectWindow(sortedFilelist[i]);

		if (RotC == RotChoice[1]) { // right (clockwise)
			run("Rotate 90 Degrees Right");
			saveAs("Tiff", outputFolder + "rot_" + sortedFilelist[i]); 
			
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Tiff", outputFolder + "MIP-" + sortedFilelist[i]); 
			
		}else if (RotC == RotChoice[2]){ // left (anti-clockwise)
			run("Rotate 90 Degrees Left");
			saveAs("Tiff", outputFolder + "rot_" + sortedFilelist[i]); 
			
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Tiff", outputFolder + "MIP-" + sortedFilelist[i]); 
		}else{ // no rotation
			print("No rotation selected");
			exit;
		}
		close("*");

	}
}
run("Close All");

print("Output Directory: " + outputFolder);

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// show message when Macro is finished
showMessage("Macro is finished"); 