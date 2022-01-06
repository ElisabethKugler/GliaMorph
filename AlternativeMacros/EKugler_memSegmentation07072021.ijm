///// prompt user to select input folder
path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// create output folder
OutputDir = path + "/TH_29072021v4/"; 
File.makeDirectory(OutputDir);

OutputDirMIPs = OutputDir + "/MIPs/"; 
File.makeDirectory(OutputDirMIPs);

print("Input Directory: " + path);

setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);


///// open images from inputfolder
for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".czi"
	if (endsWith(sortedFilelist[i], ".tif")) {
	// show rogress
	showProgress(i+1, sortedFilelist.length);
	print("processing ... " + sortedFilelist[i]);

	open(path + sortedFilelist[i]);
	rename("img");

	getDimensions(width, height, channels, slices, frames);
	halfPos = round(slices / 2);
	setSlice(halfPos);
	run("Enhance Contrast", "saturated=0.35");
/*
	run("Split Channels");
	selectWindow("C1-" + "img");
	close();
	selectWindow("C2-" + "img");
*/	
	// bleach correction in z direction as there is a significant signal decay axially
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	//selectWindow("DUP_C2-" + "img");
	selectWindow("DUP_" + "img");
	// pre-processing
	run("8-bit");
	wait(2000);
	run("Median 3D...", "x=2 y=2 z=2");
	wait(2000);
	
	// segmentation
	setSlice(halfPos);
//	setThreshold(125, 255);
//	setOption("BlackBackground", false);
//	run("Convert to Mask", "method=Intermodes background=Dark");

	//setThreshold(5, 255);
	//setOption("BlackBackground", false);
	//run("Convert to Mask", "method=Otsu background=Dark");
	
	run("Enhance Contrast", "saturated=0.35");
	wait(1000);
		
run("Threshold...");
setAutoThreshold("Default dark stack");
//setAutoThreshold("Otsu dark stack");
setOption("BlackBackground", false);
run("Convert to Mask", "method=Otsu background=Dark");

	
	// fill 3D holes
	//run("3D Fill Holes");
	run("Fill Holes", "stack");
	wait(500);

	saveAs("Tiff", OutputDir + "TH_" + sortedFilelist[i]); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Jpeg", OutputDirMIPs + "MAX_TH_" + sortedFilelist[i]); 
	close();
		
/*	run("Duplicate...", "duplicate");
	
	// smooth surfaces for skeleton
	run("Median 3D...", "x=3 y=3 z=3");
	setThreshold(125, 255);
	run("Make Binary", "method=Intermodes background=Dark");
	
*/

	// extract 3D skeleton
//	run("Skeletonize (2D/3D)");
//	saveAs("Tiff", OutputDir + "Skel_" + sortedFilelist[i]); 
//	run("Z Project...", "projection=[Max Intensity]");
//	saveAs("Jpeg", OutputDirMIPs + "MAX_Skel_" + sortedFilelist[i]); 

	close("*");

	// no inversion watershed
	//run("Distance Transform Watershed 3D", "distances=[City-Block (1,2,3)] output=[16 bits] normalize dynamic=8 connectivity=26");
	//close();
	}
}

run("Close All");

print("Output Directory: " + OutputDir);

run("Collect Garbage");

// show message when Macro is finished
showMessage("Macro is finished"); 