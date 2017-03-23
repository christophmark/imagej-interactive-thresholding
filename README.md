# Interactive thresholding with ImageJ/Fiji
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Image segmentation](https://en.wikipedia.org/wiki/Image_segmentation) and [thresholding](https://en.wikipedia.org/wiki/Thresholding_(image_processing)) plays an important part in the quantification of image data in cell biology and other areas of research. Image processing programs like [ImageJ](http://imagej.net)/[Fiji](https://fiji.sc/) offer a variety of methods to [automatically find a suitable threshold value](http://imagej.net/Auto_Threshold) to separate foreground elements, e.g. cells in a microscope image, from the noisy background and subsequently measure their size or determine the fluorescence intensity within the segmented regions in a different image channel. When combined with further image enhancement techniques like [adaptive background subtraction](http://imagej.net/Rolling_Ball_Background_Subtraction), automatic thresholding is relatively robust against varying illumination across individual images.

Analyzing a large number of images automatically, however, one will almost always find some images for which even elaborate automatic thresholding methods fail to detect the foreground elements correctly. In this case, a semi-automatic approach that still allows the user to change the automatically detected regions prior to measuring cell sizes or fluorescence intensities can help to improve the accuracy of the analysis.

This repository contains two ImageJ macros that automate a common workflow in cell biology:
- import a collection of images
- enhance image quality/contrast
- threshold all images individually
- allow user to dis-/connect and add/remove/change segmented regions
- analyze the covered area fraction per image or the size of individual regions/objects
- analyze the intensity values of segmented image regions with respect to an additional image channel
- save summarized results to file

## Usage
This repository contains two different macros:
- `FluorescenceIntensityAnalysis.ijm` is a general macro to threshold (fluorescent) objects in images and automatically analyze the area fraction covered by those objects in a series of images, or measure the area of individual objects. Furthermore, a second series of images can be supplied to automatically analyze the intensity values in these images, based on the segmented regions.

- `NucleiFluorescenceIntensity.ijm` is a more specialized version of the first macro, and focuses on detecting cell nuclei in one fluorescence channel (tested with [DAPI](https://en.wikipedia.org/wiki/DAPI)). The macro subsequently measures the intensity of those nuclei in a second fluorescence channel. It can be used to check the number of nuclei expressing a certain protein, and to estimate the corresponding expression level for individual nuclei. To separate clumps of nuclei, the macro applies [Watershed Separation](http://imagej.net/Nuclei_Watershed_Separation). Again, the user may review the automatic detection and separation of the nuclei, and change any erroneous detections before the automatic analysis.

## Usage
Macros are simple scripts that execute a series of ImageJ-commands/functions sequentially and may feature a graphical interface for the user to enter parameters. A thorough introduction to the use and development of macros can be found [here](https://imagej.nih.gov/ij/developer/macro/macros.html).

To execute a macro in ImageJ/Fiji, simply click `Plugins > Macros > Run...` and choose the macro file you want to execute. Furthermore, if you want to edit the default parameters that are displayed in the graphical interface or edit any other aspect of the macros, got to `Plugins > Macros > Edit...`. The macro editor also provides a convenient `Run` button to start the macro. The latter option is also recommended if one needs to execute the macro multiple times.

Running one of the macros, a graphical interface appears and prompts the user to enter specific parts of the filenames to import. A typical folder may contain the following images:
```
2017-03-23_exp001_img001_FITC.tiff
2017-03-23_exp001_img001_GFP.tiff
2017-03-23_exp001_img002_FITC.tiff
2017-03-23_exp001_img002_GFP.tiff
2017-03-23_exp001_img003_FITC.tiff
2017-03-23_exp001_img003_GFP.tiff
...
```
To threshold the objects using the FITC channel, enter `FITC` in the `Segmentation channel` textbox of the graphical interface. This tells the macro to import all files with a filename that contains the expression `FITC`. If you want to analyze the GFP fluorescence intensity of the segmented regions, type `GFP` into the `Read-out channel` textbox. The macro will then import the GFP images, transfer the segmented regions from the FITC images onto the GFP images and read out the intensity values. Note that a single channel can be chosen twice, as both segmentation channel and read-out channel. If one is only interested in area/size analysis, check the `Only analyze area/size`-box. The read-out channel entry is ignored in this case. Further parameter settings are explained within the graphical user interface. After pressing `OK`, the user is prompted to choose the folder containing all images for the current analysis.

Once the automatic thresholding process finished, the macros show a composite image with the segmentation channel in contrast-enhanced grayscale and the segmented regions in red, along with a pop-up window titled `Segmentation review`. While this pop-up window is open, the regions can be edited using the Pencil/Paintbrush/... tools. Note that only changes to the red channel of the composite image will be considered in the subsequent analysis. Press the `Alt`-key together with the Paintbrush tool to erase parts of regions. Pressing `OK` in the `Segmentation review` pop-up will start the analysis.

After the analysis is finished, the results are displayed in the `Results` window and are at the same time saved next to the source images as an `xls` file (despite the Excel-format, it can be opened by other programs, as it contains plain tab-separated columns of data). Any changes to the results table may be saved via the `File > Save as...` dialog within the `Results` window.

## License
[The MIT License (MIT)](https://github.com/christophmark/imagej-interactive-thresholding/blob/master/LICENSE)
