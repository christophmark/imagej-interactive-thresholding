// ---------- Default values of segmentation parameters
segChannel = "DAPI";   // default: "DAPI"; the channel to do segmentation on
readChannel = "...";   // no default value; the fluorescence channel to measure
bgdSubtraction = true; // default: true; whether to apply background substraction to segmentation channel
bgdRadius = 300;       // default: 300; in pixels, should be chosen larger than a single cell
blurRadius = 2;        // default: 2; in pixels, larger values usually result in fewer, rounder regions
removeDiameter = 10;   // default: 10; all regions with a smaller (average) diameter are removed
fillDiameter = 50;     // default: 50: true; all holes with a smaller (average) diameter within regions are removed

// ---------- Main Dialog
Dialog.create("New fluorescence intensity analysis");
Dialog.addMessage("Please provide keywords that are part of the individual image channel file names:");
Dialog.addString("Segmentation channel:", segChannel);
Dialog.addString("Read-out channel:", readChannel);
Dialog.addMessage("-------------------------------------------------- Settings: --------------------------------------------------");
Dialog.addMessage("Rolling background subtraction: This method usually greatly improves segmentation\nfor unequally illuminated images. The radius should be larger than an individual cell.\nNote: This is only applied to the segmentation channel, not the read-out channel.");
Dialog.addCheckbox("Do rolling background subtraction", bgdSubtraction);
Dialog.addNumber("r_bgd:", bgdRadius, 0, 5, "pixels");
Dialog.addMessage("Blurring radius: Blurring the image before segmentation is needed to get large,\nconnected regions. Increasing the radius results in fewer, rounder regions, while\ndecreasing the radius may result in many small regions.");
Dialog.addNumber("r_blur:", blurRadius, 0, 5, "pixels");
Dialog.addMessage("Remove small objects: All segmented objects with an area that is smaller than a\ncircle with the specified diameter are not considered in the analysis.")
Dialog.addNumber("d_remove:", removeDiameter, 0, 5, "pixels");
Dialog.addMessage("Remove small holes: All holes within segmented objects with an area that is smaller\nthan a circle with the specified diameter are filled.")
Dialog.addNumber("d_fill:", fillDiameter, 0, 5, "pixels");
Dialog.addHelp("http://www.google.com");
Dialog.setLocation(5,5);
Dialog.show();

segChannel = Dialog.getString();
readChannel = Dialog.getString();
bgdSubtraction = Dialog.getCheckbox();
bgdRadius = Dialog.getNumber();
blurRadius = Dialog.getNumber();
removeDiameter = Dialog.getNumber();
fillDiameter = Dialog.getNumber();

removeArea = round(PI*pow(0.5*removeDiameter, 2));
fillArea = round(PI*pow(0.5*fillDiameter, 2));

// ---------- Import DAPI-images from folder into stack
dir = getDirectory("Choose source directory, which contains images.");
title = split(dir, "\\")
title = title[title.length-1]
files = getFileList(dir);
run("Image Sequence...", "open=["+dir+files[0]+"] file="+segChannel+" sort");
run("16-bit"); // just in case...

// ---------- Rolling background subtraction
if (bgdSubtraction) {
	run("Subtract Background...", "rolling="+bgdRadius+" stack");
}

// ---------- Create duplicate stack (with enhanced contrast) for later review
run("Duplicate...", "title=["+title+"-images] duplicate");
selectWindow(title+"-images");
run("Enhance Contrast...", "saturated=0.1 normalize process_all");

// ---------- Auto-threshold all images of the stack
selectWindow(title);
run("Gaussian Blur...", "sigma="+blurRadius+" stack");
run("Auto Threshold", "method=Huang white stack");

// ---------- Fill small holes
run("Set Measurements...", "  redirect=None decimal=3");
run("Invert", "stack");
selectWindow(title);
run("Invert", "stack");
run("Analyze Particles...", "size=0-"+fillArea+" show=Masks stack");
imageCalculator("Add stack", title,"Mask of "+title);
selectWindow("Mask of "+title);
close();
selectWindow(title);

// ---------- Watershed segmentation
run("Invert", "stack");
run("Watershed", "stack");

// ---------- Delete small objects
run("Analyze Particles...", "size=0-"+removeArea+" show=Masks stack");
imageCalculator("Add stack", title,"Mask of "+title);
selectWindow("Mask of "+title);
close();
selectWindow(title);
run("Invert", "stack");
run("16-bit");

// ---------- Merge images and segmentation + load load read-out channel images
run("Image Sequence...", "open=["+dir+files[0]+"] file="+readChannel+" sort");
rename("fluo-channel");
run("16-bit"); // just in case...
run("Merge Channels...", "c1=["+title+"] c3=[fluo-channel] c4=["+title+"-images] create");

setColor(1);
waitForUser( "Segmentation review", "You may now review the segmentation process and\nalter the automatically detected regions.\n----------\nUse the 'Paintbrush Tool' (or any other) to change the overlay\nmasks (press 'Alt' key to erase). Note: Only changes to the red\nchannel will be taken into account.\n----------\nOnce you are finished, press 'OK'. ");

// ---------- Close segmentation channel images
run("Split Channels");
selectWindow("C3-Composite");
close();

// ---------- Configure the quantities to measure (mean, median, ...)
run("Set Measurements...", "area mean standard modal min median area_fraction redirect=C2-Composite decimal=3");
run("Clear Results");

// ---------- Measurement loop
selectWindow("C1-Composite");
run("8-bit");
counter = 0;

// ---------- Loop over all slices in stacks, measure area (& transfer selection and measure intensity)
run("Invert", "stack"); // invert again, otherwise regions at the border will not be closed
run("ROI Manager...");

for (i=1; i<nSlices+1; i++) { 
	selectWindow("C1-Composite");
	Stack.setSlice(i);
	run("Create Selection");
	
	roiManager("Split");
	roiCount = roiManager("Count");
	for (j=0; j<roiCount; j++) { 
		roiManager("Select", j);
		roiManager("Measure");
		setResult("Image", counter, i);
		if (getResult("Area", counter) < 3) {
			IJ.deleteRows(counter, counter);
		} else {
			counter++;
		}
	}
	roiManager("Deselect");
	roiManager("Delete");
}
	
// ---------- Recalculate the area fraction as the built-in version always returns 100% in this case...
for (i=0; i<counter; i++) { 
	area = getResult("Area", i);
	setResult("%Area", i, 100*area/(getWidth()*getHeight()));
}

// ---------- Close all except table with results
selectWindow("C1-Composite");
close();
selectWindow("C2-Composite");
close();
selectWindow("ROI Manager"); 
run("Close"); 

// ---------- Save results next to source images
saveAs("Results", dir+"Results_"+title+".xls");
