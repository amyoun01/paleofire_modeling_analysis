
# paleofire_modeling_analysis

### Data from: Consequences of climatic thresholds for projecting fire activity and ecological change


Global Ecology and Biogeography:  
Young, A.M., P.E. Higuera, J.T. Abatzoglou, P.E. Duffy, and F.S. Hu. (2019).  Consequences of climatic thresholds for projecting fire activity and ecological change. Global Ecology and Biogeography. doi: dx.doi.org/10.1111/geb.12872 

Dryad Digital Repository doi: https://doi.org/10.5061/dryad.82vs647

---
These scripts were originally published with the associated datasets on the Dryad Data Repository and this work is licensed under a CC0 1.0 Universal (CC0 1.0) Public Domain Dedication license. Please cite both the published paper in the GEB paper and the Dryad Repository when using or referencing the data and code used to complete this work. 

* Paper citation: Young, A.M., P.E. Higuera, J.T. Abatzoglou, P.E. Duffy, and F.S. Hu. (2019). Consequences of climatic thresholds for projecting fire activity and ecological change. Global Ecology and Biogeography. doi, https://doi.org/10.1111/geb.12872  
* Dataset citation: Young, Adam M. et al. (2019), Data from: Consequences of climatic thresholds for projecting fire activity and ecological change, Dryad, Dataset, https://doi.org/10.5061/dryad.82vs647

Contact information: 
* Adam M. Young, Ph.D.  
email: Adam.Young[at]nau.edu  
ORCID: http://orcid.org/0000-0003-2668-2794
* Philip E. Higuera, Ph.D.  
email: philip.higuera[at]umontana.edu  
ORCID: http://orcid.org/0000-0001-5396-9956

---
Overview:

This Data Dryad archive includes metadata, code, results, and figures reproducing the results presented in Young et al. (2019). There are five main directories containing this information in this data archive: 

1. code - contains all the individual Matlab and R scripts, including customized functions, needed to conduct the analyses and produce the results presented in the main text of the manuscript. 
2. data - containing the ancillary data, pre-processed data, and citations for the raw datasets needed to conduct the analyses described in the manuscript. 

3. figures - contains three versions of the figures that appear in Young et al. (In Press). The three formats are: (MATLAB .fig, .jpeg, and .tif formats). The code to create Figs 1, 2, and 3 is available in the "../code/" directory. 

4. metadata - documentation/description of this archive using FGDC standards in an xml format, including geographic metadata for the raster datasets generated during the workflow of the analysis. This metadata was originally generated using Tkme (version 3.0.5) by Peter N. Schweitzer and updated using the USGS Metadata Wizard (version 2.0.3). The thesaurus used for keyword selection was the Global Change Master Directory (version 8.6, 2018).

5. results - series of results produced from processing the raw data stored in the '\data\' directory using the code provided. 

	--- *IMPORTANT* ---
	- We also include separate 7z compressed files for the downscaled 30-yr climatologies for each GCM from 850-1850 CE. These are separated into individual files due to their large storage size (~5 GB).

	  The four compressed folders are: 
		 1. z_GISS-E2-R.7z (4.95 GB)
		 2. z_MPI-ESM-LR.7z (7.5 MB)
		 3. z_MPI-ESM-P.7z (4.94 GB)
		 4. z_MRI-CGCM3.7z (4.96 GB)

* The raw data used to conduct these analyses are not included in this archive. These data are already archived publicly, so we do not redistribute them ourselves. Detailed descriptions of the original datasets we downloaded to run our analyses are provided, as well as download URLs when available. 

* The analyses are recre ated using the Matlab and R scripts in the \code\ directory, and if these are run they can overwrite current output in the results and figures directories downloaded with this archive. To avoid this overwriting, new output/save directories should be generated and the directory names in the scripts should be changed. 

* The Spatial_Data_Organization_Information and the Spatial_Reference_Information fields in the metadata file represent the information for the raster maps generated in this analysis for the study area of mainland Alaska. This includes the downscaled monthly GeoTIFF files and the 30-yr climatological normal grids generated. 

---
Geographical Metadata and Information for Raster Datasets of mainland Alaska:
---
Rows: 725  
Columns: 687  
Resolution (x,y [meters]): (2000,2000)  
Spatial Extent (in meters) -  
- Top: 2390439.786  
- Left: -656204.44  
- Right: 717795.56  
- Bottom: 940439.786  

#### Spatial Reference: Albers Equal Area  
Datum: North American 1983  
False Easting: 0  
False Northing: 0  
Central Meridian: -154  
Standard Parallel 1: 55  
Standard Parallel 2: 65  
Latitude of Origin: 50

#### Geographic extent (decimal degrees, degrees minutes seconds):

West:  -171.629623, 171° 37' 46.6428" W  
East:  -134.802738, 134° 48' 09.8568" W  
North:   71.516416,  71° 30' 59.0976" N  
South:   57.871126,  57° 52' 16.0530" N  

#### Information for TIFF worldfile (.tfw). All units are meters (m):  
2000
0  
0  
-2000  
-655204.44  
2389439.786  

---
Citations:
---

Global Change Master Directory (GCMD). 2018. GCMD Keywords, Version 8.6. Greenbelt, MD: Global Change Data Center, Science and Exploration Directorate, Goddard Space Flight Center (GFSC) National Aeronautics and Space Administration (NASA). URL (GCMD Keyword Forum Page): https://wiki.earthdata.nasa.gov/display/gcmdkey

Schweitzer, Peter N. Tkme: Another editor for formal metadata (version 3.0.5). U.S. Geological Survey, Reston, VA 22092. Downloaded 2018-12-12 from https://geology.usgs.gov/tools/metadata/tkme.exe 

USGS Metatdata Wizard (version 2.0.3). The Metadata Wizard was developed by the USGS Fort Collins Science Center With help from the USGS Council for Data integration (CDI) and the USGS Core Science Analytics, Synthesis, and Libraries (CSAS&L).

Young, A.M., P.E. Higuera, J.T. Abatzoglou, P.E. Duffy, and F.S. Hu. 2019. Consequences of climatic thresholds for projecting fire activity and ecological change. Global Ecology and Biogeography. doi: 10.1111/geb.12872
