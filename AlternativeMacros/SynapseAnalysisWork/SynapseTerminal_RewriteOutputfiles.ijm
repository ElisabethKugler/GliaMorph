/* Macro to rewrite output files to sort them by shape descriptor rather than input image
 * EKugler 2021
 * 
 * Author: Elisabeth Kugler 2021
 * Copyright 2021 Elisabeth Kugler, UCL
 * contact: kugler.elisabeth@gmail.com

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// data output in units [um]
 
MeasurePath = getDirectory("Input Folder");
print("Input Directory: " + MeasurePath);

filelistMeasure = getFileList(MeasurePath);
sortedFilelist = Array.sort(filelistMeasure);

setBatchMode(true); //batch mode on

// ----- rewrite 3D measuerement outputfiles

rewrite("Volume (microns^3)",0);
close("Log");

rewrite("Surface (microns^2)",1);
close("Log");

rewrite("B-width",22);
close("Log");
rewrite("B-height",23);
close("Log");
rewrite("B-depth",24);
close("Log");

close("*");
run("Collect Garbage");
setBatchMode(false); //exit batch mode

// show message when Macro is finished
showMessage("Macro is finished"); 

function rewrite(name,col) { 
	//---- rewrite files 
	// Help from Dave Mason 13112020
	// https://forum.image.sc/t/copying-entire-columns-into-new-files-fiji-macro/45182/2
	for (i=0; i< sortedFilelist.length; i++) {
		if (startsWith(sortedFilelist[i], "3DObjCounter_")) {
			//-- Read in the file as a string
			fileData=File.openAsString(MeasurePath + sortedFilelist[i]);
			column_labelM = sortedFilelist[i];
			//-- Split the whole file into lines
			fileData_lines=split(fileData, "\n");
			//-- count how many lines we have and create a new array to hold one columns worth of values
			numLines=fileData_lines.length;
			//-- create arrays for outputs
			nameArray=newArray(numLines); 
			
			//-- loop through each line
			for (k = 0; k < numLines; k++) {
			//-- For each line, split it using the comma delimiter
				fileData_columns=split(fileData_lines[k],",");
			//-- columns to output arrays
				nameArray[k] = fileData_columns[col]; 
	
			}
			// --- write arrays into output files from log
			Array.print(nameArray);
			saveAs("Text",  MeasurePath + name + ".txt"); // copy > Paste Transpose
		}		
	}
}
