/* Macro to split channels and save them in separate folders
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

// GUI to select number of channels
Dialog.create("Split channels");
choices = newArray("1", "2", "3", "4");
Dialog.addChoice("Select number of image channels:", choices);
// create dialog
Dialog.show();
// parse choice
NrC = Dialog.getChoice(); 

// prompt user for input path
path = getDirectory("Input Folder"); 
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);

setBatchMode(true); //batch mode on

print("Input Directory: " + path);

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

if(NrC==choices[0]){ // one channel
	channels=1;
}
if(NrC==choices[1]){ // two channels
	channels=2;
}
if(NrC==choices[2]){ // three channels
	channels=3;
}
if(NrC==choices[3]){ // four channels
	channels=4;
}

// create output folders
for (i = 1; i <= channels; i++) {
	CDirO = path + "/" + i + "CDir/"; 
	File.makeDirectory(CDirO);
}

// open files, split channels, and save them in respective output folders
for (i=0; i< sortedFilelist.length; i++) {   
	if (endsWith(sortedFilelist[i], ".tif")) {
		open(path + sortedFilelist[i]);
		// show rogress
		showProgress(i+1, sortedFilelist.length);
		print("processing ... " + sortedFilelist[i]);
		
		img=getTitle();
		run("Split Channels");
		
		for (k = 1; k <= channels; k++) {
		selectWindow("C"+ k + "-" + img);
		saveAs("Tiff", path + k + "CDir/" + "C" + k + "-" + img); 
		wait(3000);
		}

		close("*");
	}
}

run("Close All");

run("Collect Garbage");
setBatchMode(false); //exit batch mode

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

// show message when Macro is finished
showMessage("Macro is finished");