function [] = GCP_convert(file_in,h, ppi_in, conv_flag)

% Inputs: 
% file_in: full path the input file (to be converted). e.g. 'D:\Local\AutoGeoRef\gcp-arc\1_63360\030L13_1906.txt';
% h: height of the image for which the gcp was made (required)
% ppi_in: resolution (in points per inch) of the image for which the gcp file was made (should be included; otherwise, assumed = 600)
% conv_flag (optional): specifies which type of conversion should be made
%%%% conv_flag = 1: Convert from arcgis format to QGIS
%%%% conv_flag = 2: Convert from QGIS to arcgis format
% ppi_out (optional): the desired resolution of the output image -- used in
% creating the gdal string
%% testing only
% file_in = 'D:\Local\AutoGeoRef\gcp-qgis\1_63360\030L13_1906.tif.points';
% file_in = 'D:\Local\AutoGeoRef\gcp-arc\1_63360\030L13_1906.txt';
% info = imfinfo('H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\South_Italy_Grid\macrepo30939.tiff','tiff');

%% Settings
% Try to identify the gcp filetype from the extension
[path, fname, ext] = fileparts(file_in);

switch ext
    case '.txt'
        conv_flag_est = 1;
        conv_text = 'Arc to QGIS';
    case '.points'
        conv_flag_est = 2;
        conv_text = 'QGIS to Arc';
    otherwise
end

if nargin==2
    conv_flag = conv_flag_est;
    disp(['No conversion flag provided. Assuming conversion: ' conv_text]);
    ppi_in = 600;
    disp('No input resolution for tiff file provided. Assuming 600 ppi');
elseif nargin==3
    conv_flag = conv_flag_est;
    disp(['No conversion flag provided. Assuming conversion: ' conv_text]);
end

%% Conversion
try
switch conv_flag
    case 1 
     %% ArcGIS format to QGIS   
        gcp_fmt = '%f %f %f %f'; %input format for the Arc GCP files
        % Read the GCP file:
        fid = fopen(file_in,'r');
        C_tmp = textscan(fid,gcp_fmt,'delimiter','\t');
        C = cell2mat(C_tmp); %convert from cell array into a matrix
        fclose(fid);
        
        % format of C:
        % x (inches right) | y (inches up) | x_map (lng) | y_map (lat)
        x = C(:,1);
        y = C(:,2);
        lng = C(:,3);
        lat = C(:,4);
        
        %%%Create the qgis .points file:
        fid_qgis = fopen([path '/' fname '.tif.points'],'w');
        fprintf(fid_qgis,'%s\n','mapX,mapY,pixelX,pixelY,enable');
        fclose(fid_qgis);
        
        %%% Create format for qgis file:
        C_QGIS = [lng lat x.*ppi_in (y.*ppi_in)-h ones(length(x),1)];
        dlmwrite([path '/' fname '.tif.points'],C_QGIS,'-append','precision', '%12.8f');
        
%         C_GDAL = [x*ppi_out (h.*out_ratio)-(y*ppi_out) lng lat];
%         gdal_str = '';
%         for j = 1:1:size(C_GDAL,1)
%             gdal_str = [gdal_str '-gcp ' num2str(C_GDAL(j,1),8) ' ' num2str(C_GDAL(j,2),8) ' ' num2str(C_GDAL(j,3),8) ' ' num2str(C_GDAL(j,4),8) ' '];
%         end
     
    case 2 
        %% QGIS to Arc
        clear C_tmp;
        gcp_fmt = '%s%s%s%s%s'; %input format for the Arc GCP files
        
        % Read the GCP file:
        fid = fopen(file_in,'r');
        C_tmp = textscan(fid,gcp_fmt,'Delimiter',',');
        fclose(fid);
        for i = 1:1:5
            headers{i,1} = C_tmp{1,i}{1,1};
            C(:,i) = str2double(C_tmp{1,i}(2:end,1));
        end
        % format of C:
        % x_map (lng) | y_map (lat) | x (pixels right) | y (pixels down[-ve]) | enable (=1)
        x = C(:,3);
        y = C(:,4);
        lng = C(:,1);
        lat = C(:,2);
        %%%Create the arc .txt file:
%         fid_qgis = fopen([qgis_gcp_path filename_in '.points'],'w');
%         fprintf(fid_qgis,'%s\n','mapX,mapY,pixelX,pixelY,enable');
%         fclose(fid_qgis);
        C_ARC = [x./ppi_in (y+h)./ppi_in lng lat];
        
        fname_out = fname(1:strfind(fname,'.tif')-1);
        dlmwrite([path '/' fname_out '.txt'],C_ARC,'Delimiter','\t','precision', '%12.8f');
        
end
catch
    disp(['Conversion of file: ' file_in ' failed.']);
end
