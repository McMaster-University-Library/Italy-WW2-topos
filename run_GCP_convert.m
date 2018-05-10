process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\South_Italy_Grid\';
conv_flag = 2; % 1=ArcGIS to QGIS; 2=QGIS to ArcGIS
GCP_bulk_convert(process_dir,conv_flag);

%% North Italy Grid
process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\North_Italy_Grid\';
conv_flag = 2; % 1=ArcGIS to QGIS; 2=QGIS to ArcGIS
GCP_bulk_convert(process_dir,conv_flag);

%%
process_dir = 'D:\Local\OCUL_HTDP\gcp\gcp-arc\1_25000\';
conv_flag = 1; % 1=ArcGIS to QGIS; 2=QGIS to ArcGIS
options.ppi_in = 600;
GCP_bulk_convert(process_dir,conv_flag,options);
