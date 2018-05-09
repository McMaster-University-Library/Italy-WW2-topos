
%% Options (from georef_rewarp comments):
% 1. process_dir: The directory containing tiff files to be processed.
% 2. options:
%%% options.clipping_flag indicates whether or not a clipped (to the neatline) version should be created with the unclipped one. The clipped image is saved to /geotiff_clipped
%%%% clipping_flag = 0 indicates no clipped image to be created, while clipping_flag=1 causes a clipped image to be produced.
%%% options.georef_list: Full file path and name of a single column csv file with filenames to be processed (optional); file must exist in the process_dir
%%%% directory. where georef_list is not provided, the function works through the entire directory (dir_flag = 1)
%%% options.t_srs: The target coordinate reference system
%%% options.s_srs: The source coordinate reference system
%%% options.ppi_out: The desired resolution of the outputed georeferenced image
%%% options.ppi_in: The resolution of the input image to be georeferenced
%%% (if empty, this will be determined from the file itself)

%% South Italy Grid
process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\South_Italy_Grid';
options.clipping_flag = 0; % no clipping (not necessary)
options.georef_list = ''; %not necessary.
options.t_srs = 'PROJCS["Lambert_Conformal_Conic",GEOGCS["GCS_Bessel 1841",DATUM["unknown",SPHEROID["bessel",6377397.155,299.1528128]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_1SP"],PARAMETER["latitude_of_origin",39.5],PARAMETER["central_meridian",14],PARAMETER["scale_factor",0.99906],PARAMETER["false_easting",700000],PARAMETER["false_northing",600000],UNIT["Meter",1]]';
options.ppi_out = 300;

% Run GCP_bulk_convert to convert all QGIS GCP files to ArcGIS:
conv_flag = 2; % 1=ArcGIS to QGIS; 2=QGIS to ArcGIS
GCP_bulk_convert(process_dir,conv_flag);

% Run georeferencing:
georef_rewarp(process_dir,options);

%% North Italy Grid
process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\North_Italy_Grid';
options.clipping_flag = 0; % no clipping (not necessary)
options.georef_list = ''; %not necessary.
options.t_srs = 'PROJCS["Lambert_Conformal_Conic",GEOGCS["GCS_Bessel 1841",DATUM["unknown",SPHEROID["bessel",6377397.155,299.1528128]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_1SP"],PARAMETER["latitude_of_origin",45.9],PARAMETER["central_meridian",14],PARAMETER["scale_factor",0.99906],PARAMETER["false_easting",800000],PARAMETER["false_northing",601000],UNIT["Meter",1]]';
options.ppi_out = 300;

% Run GCP_bulk_convert to convert all QGIS GCP files to ArcGIS:
conv_flag = 2; % 1=ArcGIS to QGIS; 2=QGIS to ArcGIS
GCP_bulk_convert(process_dir,conv_flag);

% Run georeferencing:
georef_rewarp(process_dir,options);