function [] = GCP_bulk_convert(process_dir, conv_flag, options)
% process_dir: The directory (full path) within which all gcp files should be converted
%%% *** NOTE: This function expects gcp files and tif files to be in the
%%% same directory!! ***
% conv_flag (required): specifies which type of conversion should be made
%%%% conv_flag = 1: Convert from arcgis format to QGIS
%%%% conv_flag = 2: Convert from QGIS to arcgis format

if nargin < 3
    options.ppi_in = [];
    options.h = [];
else
    if isfield(options,'h')==0; options.h = [];end
    if isfield(options,'ppi_in')==0; options.ppi_in = [];end
end

% Add a trailing slash on process_dir (if it doesn't already exist)
if strcmp(process_dir(end),'\')==1 || strcmp(process_dir(end),'/')==1
else
    process_dir = [process_dir '/'];
end

% process_dir = 'H:\Digitization_Projects\WWII_Topographic_Maps\Italy\Italy_100k_TIF_600dpi\South_Italy_Grid\';
tmp_dir = dir(process_dir);

switch conv_flag
    case 1 % ArcGIS to QGIS
        for i = 1:1:length(tmp_dir)
            [fdir, fname, fext] = fileparts(tmp_dir(i).name); %file directory | filename | file extension
            if strcmp(fext,'.txt')==1
                %     d(ctr).name = tmp_dir(i).name; ctr = ctr+1;
                %     fname2 = fname(1:strfind(fname,'.tif')-1);
                % Check if there exists a a corresponding tif file
                if isempty(options.ppi_in) % If options.ppi_in is empty, we need to extract the value from the tif file itself
                    if exist([process_dir fname '.tif'],'file')==2; fname_tif = [fname '.tif'];
                    elseif exist([process_dir fname '.tiff'],'file')==2; fname_tif = [fname '.tiff'];
                    else
                        fname_tif = '';
                        continue;
                    end
                    iminfo = imfinfo([process_dir fname_tif]); ppi_in = iminfo.XResolution; h = iminfo.Height;
                else
                    ppi_in = options.ppi_in;
                    h = options.h;
                end
                GCP_convert([process_dir tmp_dir(i).name],h, ppi_in,conv_flag)
            end
        end
        
    case 2 % QGIS to ArcGIS
        for i = 1:1:length(tmp_dir)
            [fdir, fname, fext] = fileparts(tmp_dir(i).name); %file directory | filename | file extension
            if strcmp(fext,'.points')==1
                %     d(ctr).name = tmp_dir(i).name; ctr = ctr+1;
                %     fname2 = fname(1:strfind(fname,'.tif')-1);
                % Check if there exists a a corresponding tif file
                fname_tif = fname;
                if isempty(options.ppi_in)==1 || isempty(options.h)==1% If options.ppi_in or options.h is empty, we need to extract the value from the tif file itself
                    if exist([process_dir fname_tif],'file')==2
                        iminfo = imfinfo([process_dir fname_tif]); ppi_in = iminfo.XResolution; h = iminfo.Height;
                    else
                        continue;
                    end
                else
                    ppi_in = options.ppi_in;
                    h = options.h;
                end
                GCP_convert([process_dir tmp_dir(i).name],h, ppi_in,conv_flag)
            end
        end
end



