/* Macro for deconvolution of confocal images using theoretical or experimental PSF
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

///// GUI for selection of fluorophores /////
Dialog.create("DeconvolutionTool - Wavelength Selection");
BinaryChoice = newArray("no","yes");

// channels	
Dialog.addChoice("Multiple Channels:", BinaryChoice);
Dialog.addNumber("C1 emission wavelength (nm):", 0);
Dialog.addNumber("C2 emission wavelength (nm):", 0);
Dialog.addNumber("C3 emission wavelength (nm):", 0);
Dialog.addNumber("C4 emission wavelength (nm):", 0);
Dialog.addMessage("***Emission nm for some standard fluorophores: \n DAPI 455, CFP 485, venusPest 512, GFP 510, dsRed 586, \n Alexa568 603, mCherry 610, Alexa647 667, Alexa680 702***");
Dialog.addNumber("Select Objective NA [e.g. 20x Air 0.8, 40x Water 1.3, 63x Oil 1.4]:", 1.30);
Dialog.addChoice("Does PSF exist?", BinaryChoice);
// create dialog
Dialog.show();

// parse choices and input
MultipleC = Dialog.getChoice(); 
channel_1 = Dialog.getNumber(); 
channel_2 = Dialog.getNumber(); 
channel_3 = Dialog.getNumber(); 
channel_4 = Dialog.getNumber();
ObjNA = Dialog.getNumber();
PSFexists = Dialog.getChoice(); 

channels = newArray(channel_1,channel_2,channel_3,channel_4);

// prompt user for input directory
path = getDirectory("Input Folder");
filelist = getFileList(path);
sortedFilelist = Array.sort(filelist);

print("Input Directory: " + path);

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

///// which channels and signal /////
cNrA = 0; cNrB = 0; cNrC = 0; cNrD = 0; 
if (channel_1 != 0){ 
	cNrA = 1;
	cNrAPSF = channel_1;
}
if (channel_2 != 0){ 
	cNrB = 2;
	cNrBPSF = channel_2;
}
if (channel_3 != 0){ 
	cNrC = 3;
	cNrCPSF = channel_3;
}
if (channel_4 != 0){ 
	cNrD = 4;
	cNrDPSF = channel_4;
}

// create output directory
PSFDir = path + "/PSFDir/"; 
File.makeDirectory(PSFDir);
DeconvDir = path + "/DeconvDir/"; 
File.makeDirectory(DeconvDir);

///// if multiple channels - create outputDirs for channels
if (MultipleC==BinaryChoice[1]){ // yes
	ChannDir = path + "/ChannDir/"; 
	File.makeDirectory(ChannDir);
}else { // single-channel
	// ChannDir = path;
	ChannDir = path + "/ChannDir/"; 
	File.makeDirectory(ChannDir);
}


///// if PSF file exists (i.e. measured or theoretical) prompt user to provide PSF file info 
if (PSFexists==BinaryChoice[1]){ // PSF exists	
	if (channel_1 != 0){ 
		cNrAPSF = File.openDialog("Choose file for C1 PSF"); // path
		cNrAPSFn = File.getName(cNrAPSF);
		cNrAPSFDir = File.getParent(cNrAPSF);
	}
	if (channel_2 != 0){ 
		cNrBPSF = File.openDialog("Choose file for C2 PSF");
		cNrBPSFn = File.getName(cNrBPSF);
		cNrBPSFDir = File.getParent(cNrBPSF);
	}
	if (channel_3 != 0){ 
		cNrCPSF = File.openDialog("Choose file for C3 PSF");
		cNrCPSFn = File.getName(cNrCPSF);
		cNrCPSFDir = File.getParent(cNrCPSF);
	}
	if (channel_4 != 0){
		cNrDPSF = File.openDialog("Choose file for C4 PSF");
		cNrDPSFn = File.getName(cNrDPSF);
		cNrDPSFDir = File.getParent(cNrDPSF);
	}
}


///// open and iterate through images
for (i=0; i< sortedFilelist.length; i++) {   
		if (endsWith(sortedFilelist[i], ".tif")) {
			open(path + sortedFilelist[i]);

			getVoxelSize(width, height, depth, unit);
			prewidth = width;
			preheight = height;
			predepth = depth;
			preunit = unit;

			// check whether image is multichannel
			if (MultipleC==BinaryChoice[1]){ // multiple channels exist
				run("Split Channels");
				print("Multiple channels as input.");
			}else{ // only one channel
				selectWindow(sortedFilelist[i]);
				rename("C" + cNrA + "-" + sortedFilelist[i]);
				print("Single channel as input.");
			}

			// check whether PSF files exist (an be experimentally derived or theoretically created)
			if (PSFexists==BinaryChoice[1]){ 	// PSF file for deconvolution exists i.e. when images acquired with the same specifications	
				// parse PSF files from above to str / psf file etc
				// need to split C's (splitting above) and save in ChannDir - maybe take from below and do above? 
				// rename str					
				PSFexisting(sortedFilelist[i]);
				
			}else{	// PSF files are needed; here, they will be made for each image and then images deconvolved				
				// calls PSF function - depending on Tg's and performs deconvolution
			 	PSF(sortedFilelist[i]);
				
			}
		}
}


run("Close All");
print("Output Directory: " + DeconvDir);
run("Collect Garbage");
//setBatchMode(false); //exit batch mode

// show message when Macro is finished
showMessage("Macro is finished"); 

///// function for deconvolution with existing PSF file 
function PSFexisting(title){
	if (channel_1 != 0){ 
		selectWindow("C" + cNrA + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		image = " -image file " + ChannDir + str;
		psf = " -psf file " + cNrAPSFDir + "/" + cNrAPSFn;
		decon=getTitle();
  		confocal(decon);
	}
	if (channel_2 != 0){ 
		selectWindow("C" + cNrB + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		image = " -image file " + ChannDir + str;
		psf = " -psf file " + cNrBPSFDir + "/" +  cNrBPSFn;
		decon=getTitle();
  		confocal(decon);
	}
	if (channel_3 != 0){
		selectWindow("C" + cNrC + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		image = " -image file " + ChannDir + str;
		psf = " -psf file " + cNrCPSFDir + "/" + cNrCPSFn;
		decon=getTitle();
  		confocal(decon);
	}
	if (channel_4 != 0){ 
		selectWindow("C" + cNrD + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		image = " -image file " + ChannDir + str;
		psf = " -psf file " + cNrDPSFDir + "/" + cNrDPSFn;
		decon=getTitle();
  		confocal(decon);
	}
	
}

///// function to create theoretical PSF
function PSF(title){
// convert um to nm
newPixelWidth = prewidth * 1000; 
newPixelHeight = preheight * 1000;
newVoxelDepth = predepth * 1000;

	if (channel_1 != 0){
		// select image with with channel number cNrA
		selectWindow("C" + cNrA + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		decon=getTitle();
		// create theoretical PSF
		run("Diffraction PSF 3D", "index=1.330 numerical=" + ObjNA + " wavelength=" + channel_1 + " longitudinal=0 image=" + newPixelWidth + " slice=" + newVoxelDepth + " width,=256 height,=256 depth,=256 normalization=[Sum of pixel values = 1] title=PSF");
  		selectWindow("PSF");
  		saveAs("Tiff", PSFDir + str);
  		psfFile = getTitle();
  		image = " -image file " + ChannDir + str;
		psf = " -psf file " + PSFDir + psfFile;
  		confocal(decon);

	}
	if (channel_2 != 0){
		selectWindow("C" + cNrB + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		decon=getTitle();
		// create theoretical PSF
		run("Diffraction PSF 3D", "index=1.330 numerical=" + ObjNA + " wavelength=" + channel_2 + " longitudinal=0 image=" + newPixelWidth + " slice=" + newVoxelDepth + " width,=256 height,=256 depth,=256 normalization=[Sum of pixel values = 1] title=PSF");
  		selectWindow("PSF");
  		saveAs("Tiff", PSFDir + str);
  		psfFile = getTitle();
  		image = " -image file " + ChannDir + str;
		psf = " -psf file " + PSFDir + psfFile;
  		confocal(decon);

	}
	if (channel_3 != 0){ 
		selectWindow("C" + cNrC + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		decon=getTitle();
		// create theoretical PSF
		run("Diffraction PSF 3D", "index=1.330 numerical=" + ObjNA + " wavelength=" + channel_3 + " longitudinal=0 image=" + newPixelWidth + " slice=" + newVoxelDepth + " width,=256 height,=256 depth,=256 normalization=[Sum of pixel values = 1] title=PSF");
		selectWindow("PSF");
  		saveAs("Tiff", PSFDir + str);
  		psfFile = getTitle();
  		image = " -image file " + ChannDir + str;
		psf = " -psf file " + PSFDir + psfFile;
  		confocal(decon);

	}
	if (channel_4 != 0){
		selectWindow("C" + cNrD + "-" + sortedFilelist[i]);
		setVoxelSize(prewidth, preheight, predepth, preunit);
		str=getTitle();
		saveAs("Tiff", ChannDir + str);
		decon=getTitle();
		// create theoretical PSF
		run("Diffraction PSF 3D", "index=1.330 numerical=" + ObjNA + " wavelength=" + channel_4 + " longitudinal=0 image=" + newPixelWidth + " slice=" + newVoxelDepth + " width,=256 height,=256 depth,=256 normalization=[Sum of pixel values = 1] title=PSF");
  		selectWindow("PSF");
  		saveAs("Tiff", PSFDir + str);
  		psfFile = getTitle();
  		image = " -image file " + ChannDir + str;
		psf = " -psf file " + PSFDir + psfFile;
  		confocal(decon);
		}	

print("Theoretical PSF(s) created " + sortedFilelist[i]);
}

///// function for the actual deconvolution step
function confocal(title) {
		// deconvolution params
		algorithm = " -algorithm RL 1";
		parameters = "";
		// run PSF deconvolution
		run("DeconvolutionLab2 Run", image + psf + algorithm + parameters);
		wait(50000); // wait: for bug "No window: Final Display of RL" - Macro wants to call next line before finishing deconvolution - wait function solved this
		
		selectWindow("Final Display of RL");
		setVoxelSize(prewidth, preheight, predepth, preunit);
		saveAs("Tiff", DeconvDir + str);
		close("*");
		print("Confocal pre-processing done " + sortedFilelist[i]);
}

// runTime check
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print(hour + ":" + minute + ":" + second);

run("Close All");
showMessage("Analysis finished");
