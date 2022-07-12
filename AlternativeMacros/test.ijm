// prompt for folder with segmented synapse terminals
inputFolder = getDirectory("Input Folder"); 
filelist = getFileList(inputFolder);
sortedFilelist = Array.sort(filelist);

// output folder
Output = inputFolder + "/Output/"; 
File.makeDirectory(Output);

setForegroundColor(255, 255, 255); 
setBackgroundColor(0, 0, 0); 

for (i=0; i< sortedFilelist.length; i++) {
		if (endsWith(sortedFilelist[i], ".tif")) {
			// open segmented synapse terminals
			open(inputFolder + sortedFilelist[i]);
			selectWindow(sortedFilelist[i]);
			
			run("8-bit");
			run("Fire");
			wait(3000);
			saveAs("Tiff", Output + "fire_" + sortedFilelist[i]); 
			
			}
}