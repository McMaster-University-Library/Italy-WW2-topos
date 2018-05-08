% function [logfile] = georef_rewarp(process_dir, georef_list, clipping_flag, ppi_out)
function [logfile] = georef_rewarp(process_dir, options)

% georef_rewarp.m
% This function runs through a collection of maps sheets (whether 1:25000 or 1:63360, as specified by series_label),
% looks for corresponding gcp files--and where they exist, performs georeferencing and georectification.
%%% inputs:
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

%%% Running this on Windows requires setting up GDAL, Python and GDAL
%%% Python bindings correctly, as well as Environment variable PATH values
% see: https://pythongisandstuff.wordpress.com/2011/07/07/installing-gdal-and-ogr-for-python-on-windows/
%% Testing purposes only
% process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\South_Italy_Grid';
% options.clipping_flag = 0;
% options.georef_list = '';
% options.t_srs = 'PROJCS["Lambert_Conformal_Conic",GEOGCS["GCS_Bessel 1841",DATUM["unknown",SPHEROID["bessel",6377397.155,299.1528128]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_1SP"],PARAMETER["latitude_of_origin",39.5],PARAMETER["central_meridian",14],PARAMETER["scale_factor",0.99906],PARAMETER["false_easting",700000],PARAMETER["false_northing",600000],UNIT["Meter",1]]';
% options.ppi_out = 300;
% nargin = [1232];
%% Settings
if nargin == 0
    disp('The variables ''process_dir'' and ''options'' must be set. Exiting.');
    return;
end
% elseif nargin == 1
%     dir_flag = 1; % if only one argument (series label) is provided, then run through the entire /tif directory
%     options = struct();
% %     clipping_flag = 0;
% %     ppi_out = 300;
% elseif nargin ==2
%     dir_flag = 0; % if a list is provided, the function will run through all filenames provided in the list.
%     options = struct();
% % elseif nargin ==3
% %     ppi_out = 300;
% else
%     dir_flag = 0;
dir_flag = 0;
if ~isfield(options,'georef_list')
    dir_flag = 1;
else
    if isempty(options.georef_list)==1; dir_flag = 1; end
end

if ~isfield(options,'ppi_out'); options.ppi_out = 300; disp('options.ppi_out not set; Assuming 300 ppi output resolution.');end
if ~isfield(options,'clipping_flag'); options.clipping_flag = 0; disp('options.clipping_flag not set; Setting to 0 (no clipping).');end
if ~isfield(options,'ppi_in'); options.ppi_in = []; disp('options.ppi_in not set; Will determine from image metadata.');end

% Add a trailing slash on process_dir (if it doesn't already exist)
if strcmp(process_dir(end),'\')==1 || strcmp(process_dir(end),'/')==1
else
    process_dir = [process_dir '/'];
end
%% Paths
georef_path = [process_dir 'georef/'];
if exist(georef_path,'dir')~=7
    mkdir(georef_path);
end
% tiles_path = [master_path 'tiles/'];

%%% Try and figure out the OSGeo directory on windows
if ispc ==1
    if exist('C:\Program Files\GDAL\gdal_translate.ex1','file')==2
        OSGeo_dir = 'C:\Program Files\GDAL\';
    elseif exist('C:\OSGeo4W64\bin\gdal_translate.exe','file')==2
        OSGeo_dir = 'C:\OSGeo4W64\bin\';
    elseif exist('C:\Program Files\QGIS 3.0\bin\gdal_translate.exe','file')==2
        OSGeo_dir = 'C:\Program Files\QGIS 3.0\bin\';    
    elseif exist('C:\Program Files\QGIS 2.18\bin\gdal_translate.exe','file')==2
        OSGeo_dir = 'C:\Program Files\QGIS 2.18\bin\';
    else
        disp('Can''t find the OSGeo directory--add it to georef_reward line ~70');
    end
end
%% Variables

% gdal_translate -of GTiff -gcp [pixelx pixely easting northing] -gcp [pixelx pixely easting northing] -gcp [pixelx pixely easting northing] -gcp [pixelx pixely easting northing] "input_map.tiff" "output_gcp.tiff"
% gdalwarp - r near -order 1 -co COMPRESS=NONE -dstalpha "output_gcp.tiff" "output_warp.tiff"

%%%%%%%%%%%%%%%% Put together a list of files to process
switch dir_flag
    case 0 % in this case, we'll process from the georef_list file
        % load the processing list:
        fid_list = fopen(georef_list);
        tmp_dir = struct;
        tmp = textscan(fid_list, '%s','Delimiter',',');
        for i = 1:1:size(tmp{1,1},1)
            tmp_dir(i).name = tmp{1,1}{i,1};
            tmp_dir(i).isdir = 0;
        end
        fclose(fid_list);
    case 1
        tmp_dir = dir(process_dir);
end

%%% Clean this list to include only those with .tif or .tiff extensions
ctr = 1;
d = struct;
for i = 1:1:length(tmp_dir)
    [fdir, fname, fext] = fileparts(tmp_dir(i).name); %file directory | filename | file extension
    if tmp_dir(i).isdir==0 && (strcmp(fext,'.tif')==1 || strcmp(fext,'.tiff')==1) % If we're dealing with a tif file:
        d(ctr).name =  tmp_dir(i).name;
        ctr = ctr+1;
    end
end
clear tmp_dir;

%% Main loop

logfile = cell(length(d),2);
%% Cycle through the tif files:
for i = 1:1:length(d)
    % get the filename of the tif file:
    filename_in = d(i).name;
    [fdir, fname, fext] = fileparts(filename_in); %file directory | filename | file extension
    logfile{i,1} = filename_in;
    
    % look for the corresponding GCP file in the same directory (named the same but with .txt extension)
    if exist([process_dir fname '.txt'],'file')==2
        disp(['Now working on file: ' filename_in]);
        
        %%%%%%%%%%%%% Load the ArcGIS GCP file:
        gcp_fmt = '%f %f %f %f'; %input format for the Arc GCP files
        % Read the GCP file:
        fid = fopen([process_dir fname '.txt'],'r');
        C_tmp = textscan(fid,gcp_fmt,'delimiter','\t');
        C = cell2mat(C_tmp); %convert from cell array into a matrix
        fclose(fid);
        %%% Put something in here that will take a look at the number of points in the GCP file, and decide which transformation to use:
        if size(C,1)>6; trans_order = '2'; else trans_order = '1'; end
        % format of C: x (inches right) | y (inches up) | x_map (lng) | y_map (lat)
        x = C(:,1);
        y = C(:,2);
        lng = C(:,3);
        lat = C(:,4);
        
        % Get image resolution from file metadata (if options.ppi_in is empty):
        iminfo = imfinfo([process_dir filename_in]); ppi_in = iminfo.XResolution; h=iminfo.Height;

%         if ~isempty(options.ppi_in)
%             
%         else
%             ppi_in = options.ppi_in;
%         end
        
        %%%%%%%%%%%%%%%%%%%%%%%%% GDAL Translate (gdal_translate) %%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%% Generate gdal_translate string
        % ratio of ppi_out to ppi_in
        out_ratio = options.ppi_out./ppi_in;
        out_pct = round(out_ratio*10000)./100;
        disp(['out_ratio is: ' num2str(out_ratio) '. out_pct = ' num2str(out_pct)]);
        
        C_GDAL = [x*options.ppi_out (h.*out_ratio)-(y*options.ppi_out) lng lat];
        gdal_str = '';
        for j = 1:1:size(C_GDAL,1)
            gdal_str = [gdal_str '-gcp ' num2str(C_GDAL(j,1),8) ' ' num2str(C_GDAL(j,2),8) ' ' num2str(C_GDAL(j,3),8) ' ' num2str(C_GDAL(j,4),8) ' '];
        end
        
        %%% Try and execute GDAL translate command:
        gdal_trans_cmd = ['-q -of GTiff -outsize ' num2str(out_pct) '% ' num2str(out_pct) '% ' gdal_str '"' process_dir filename_in '" "' process_dir 'tmp.tif"'];
        disp(gdal_trans_cmd);
        disp(['Running gdal_translate on ' filename_in '.']);
        if ispc==1
            gdal_trans_cmd = ['"' OSGeo_dir 'gdal_translate" ' gdal_trans_cmd];
            [status_trans, msg_trans] = dos(gdal_trans_cmd);
        else [status_trans] = unix(['gdal_translate ' gdal_trans_cmd]);
        end
        if status_trans~=0
            disp(['gdal_translate failed for: ' filename_in '. Skipping.']);
            logfile{i,2} = 'gdal_translate';
            continue
        end
            disp(['Transformation of ' filename_in ' was successful.']);
            logfile{i,2} = 'clear!';

        %%%%%%%%%%%%%%%%%%%%%%%%% GDAL warp (gdalwarp) %%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%% Try the gdalwarp command:
            gdalwarp_cmd = ['-overwrite -q -r cubicspline -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' process_dir 'tmp.tif" "' georef_path fname '.tif"'];
%             gdalwarp_cmd = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:' t_srs{k} ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "' georef_path]...
%                 geotiff_path t_srs_tag{k} '/' filename_in '"'];
            disp(['Running gdalwarp on ' filename_in '.']);
            
            if ispc==1
                gdalwarp_cmd = ['"' OSGeo_dir 'gdalwarp" ' gdalwarp_cmd];
                [status_warp, msg_warp] = dos(gdalwarp_cmd);
            else [status_warp] = unix(['gdalwarp ' gdalwarp_cmd]);
            end
            
            if status_warp~=0
                disp(['gdalwarp failed for: ' filename_in '. Skipping.']);
                logfile{i,2} = 'gdalwarp';
                continue
                
            end
            disp(['Warping of ' filename_in ' was successful.']);
            logfile{i,2} = 'clear!';
            
            %%%%%%%%%%%%%%%% Assigning coordinate system: (gdal_edit) %%%%%%%%%%%%%
            gdaledit_cmd = ['-a_srs ' options.t_srs ' "' georef_path fname '.tif"'];
            disp(['Running gdaledit on ' filename_in '.']);
            
            if ispc==1
                gdaledit_cmd = ['gdal_edit.py ' gdaledit_cmd];
                [status_edit, msg_edit] = dos(gdaledit_cmd);
            else [status_edit] = unix(['gdal_edit ' gdaledit_cmd]);
            end
            
            if status_edit~=0
                disp(['gdal_edit failed for: ' filename_in '. Skipping.']);
                logfile{i,2} = 'gdal_edit';
                continue
            end
            disp(['gdal_edit for ' filename_in ' was successful.']);
            logfile{i,2} = 'clear!';
            
            %%%%%%%%%%%%%%%% CLIPPING -- needs to be further developed%%%%%
            %%% if clipping_flag==1, run gdalwarp command again, but clip to the neatline.
%             if clipping_flag==1
%                 gdalwarp_cmd2 = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:4269 -te ' num2str(lng_min) ' ' num2str(lat_min) ' ' num2str(lng_max) ' ' num2str(lat_max) ' -te_srs EPSG:' te_srs ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "' geotiff_clipped_path t_srs_tag{k} '/' filename_in '"'];
%                 %          gdalwarp_cmd2 = ['gdalwarp -overwrite -q -r cubicspline -s_srs EPSG:' s_srs ' -t_srs EPSG:' t_srs{k} ' -te ' num2str(lng_min) ' ' num2str(lat_min) ' ' num2str(lng_max) ' ' num2str(lat_max) ' -te_srs EPSG:' te_srs ' -order ' trans_order ' -co COMPRESS=NONE -dstalpha "' master_path 'tmp.tif" "' geotiff_clipped_path t_srs_tag{k} '/' filename_in '"'];
%                 
%                 disp(['Running gdalwarp (clipped) on ' filename_in '.']);
%                 
%                 if ispc==1;
%                     gdalwarp_cmd2 = [OSGeo_dir gdalwarp_cmd2];
%                     [status_warp2, msg_warp2] = dos(gdalwarp_cmd2);
%                 else [status_warp] = unix(gdalwarp_cmd2);
%                 end
%                 
%                 if status_warp2~=0
%                     disp(['gdalwarp (clipped) failed for: ' filename_in '. Skipping.']);
%                     %logfile{i,2} = 'gdalwarp';
%                     continue
%                 end
% 
%             end
   %%% Copy the file (and all related files) to the /completed-tocheck/
   %%% folder
   move_list = {[process_dir filename_in], [process_dir 'completed-tocheck/' filename_in];...
       [process_dir fname '.txt'], [process_dir 'completed-tocheck/' fname '.txt'];...
       [process_dir filename_in '.points'], [process_dir 'completed-tocheck/' filename_in '.points']};
   for j = 1:1:size(move_list,1)
       try
           status = movefile(move_list{j,1},move_list{j,2});
       catch
           status = 0;
           
       end
       if status == 0; disp(['Error moving file ' move_list{j,1} ' to /completed-tocheck/']);end
   end
    else
        disp(['Could not find the gcp file for: ' filename_in '. Breaking loop.']);
        logfile{i,2} = 'no_gcp';
        continue
    end
end

%%% Save the log file: 
fid = fopen([process_dir 'logfile_' datestr(now,30) '.txt'],'w+');
for i = 1:1:size(logfile,1)
fprintf(fid,'%s\t %s\n',logfile{i,:});
end
fclose(fid);
