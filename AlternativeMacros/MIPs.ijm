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

setForegroundColor(0, 0, 0); 
setBackgroundColor(255, 255, 255);

path = getDirectory("Input Folder");
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);
	
MIPsDir = path + "/MIPs/"; 
File.makeDirectory(MIPsDir);
	
setBatchMode(true); //batch mode on
print("Input Directory: " + path);

//iterate through input directory
for (i=0; i< sortedFilelist.length; i++) {
	if (endsWith(sortedFilelist[i], ".tif")) {
		open(path + sortedFilelist[i]);
		selectWindow(sortedFilelist[i]);
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Tiff", MIPsDir + "MIP_" + sortedFilelist[i]);
			}
	}

close("*");

run("Collect Garbage");
setBatchMode(false); //exit batch mode

run("Close All");
showMessage("Macro is finished"); 