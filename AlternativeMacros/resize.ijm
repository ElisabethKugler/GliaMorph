path = getDirectory("Input Folder"); 
filelist = getFileList(path); 
sortedFilelist = Array.sort(filelist);

///// output folders
OutputDir = path + "/Resize/"; 
File.makeDirectory(OutputDir);



for (i=0; i< sortedFilelist.length; i++) {   
	// only open images that end in ".tif"
	if (endsWith(sortedFilelist[i], ".tif")) {
		open(path + sortedFilelist[i]);

		getDimensions(width, height, channels, slices, frames);
		halfWidth = round(width/2);
		halfHeight = round(height/2);
		run("Scale...", "x=0.25 y=0.25 z=1.0 width=" + halfWidth +" height=" + halfHeight + " depth=" + slices + " interpolation=Bicubic average process create"); // why would I need to scale here?
		saveAs("Tiff", OutputDir + "Resize_" + sortedFilelist[i]);
		close();
	}
}
close("*");