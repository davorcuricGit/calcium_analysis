
function [ImgF, segs, goodFrames, badFrames, subject_json,validPixels, ME] = load_calcium(subject_json, params)

%set loading parameters. This can also be specified outside for looping
%through projects.

ImgF = [];
segs = [];
goodFrames = [];
badFrames = [];
validPixels = [];

if ~exist('params', 'var')
    params = struct(err = 0,...
        warp = 1, ...
        batch_blocks = 4, ...
        tSteps = 2000, ...
        down_sample = 2 ...
        );
end

%get recording
%try
    %get motion periods
    [segs, goodFrames, ME] = get_segments_to_keep(subject_json, params);

    if strcmp(ME.identifier, 'MATLAB:badsubscript')
        subject_json = update_json(subject_json, false, struct(step = 'loading', type = '', message = ME));
        save_json(subject_json, params)

    else
        %filter good frames and get badframes
        goodFrames = [goodFrames(cellfun(@length, goodFrames) > params.raw_parameters.good_frames_thresh)];


        %get the raw recording
        if isfield(params.raw_parameters, 'tSteps')
            if isnumeric(params.raw_parameters.tSteps)
                tSteps = params.raw_parameters.tSteps;
            else
                tSteps = subject_json.init.duration;
            end
        else
            tSteps = subject_json.init.duration;
        end


        h = subject_json.init.height;
        w = subject_json.init.width;
        recording_path = get_raw_loc(subject_json, params);
        if ~contains(subject_json.init.name, 'fChan')
            'loading .raw'
            ImgF = F_ReadRAW([recording_path '/' subject_json.init.name '.raw'], [h,w, tSteps], subject_json.init.machine_p, params.raw_parameters.warp, params.raw_parameters.err, 0, params.raw_parameters.batch_blocks, params);
        elseif contains(subject_json.init.name, 'fChan')
            'loading fChan...'
            % load the Fchan data
            
            datflou = load([recording_path '/Data_Fluo.mat']);
            fStep = datflou.datLength;
            freq = datflou.Freq;
    
            [ImgF,Fs] = F_ReadDAT([recording_path '/'], fStep);

            
            'processing...'
            F0 = mean(ImgF, 3);
            ImgF=(ImgF-F0)./F0*100;
            ImgF = F_Filt(ImgF, params.ImgF_processing.band, Fs);

            
            %now apply imwarp
            'warping ....'

            
            if params.raw_parameters.warp==1
            
            load([recording_path '/transform.mat'],'tform');
            load(fullfile(params.calcium_analysis_root, 'codes', 'matlab', 'auxfiles', 'allenDorsalMap_donovan.mat'),'dorsalMaps');
            
            if params.raw_parameters.batch_blocks <= 1
                ImgF=output_warped(ImgF,tform,dorsalMaps);
            else
                Sxyz = size(ImgF);
                nblocks = params.raw_parameters.batch_blocks;
                blocks = 1:Sxyz(3);
                blocks = reshape(blocks(1:end - mod(Sxyz(3), nblocks)), [], nblocks)';
                imgFwarped = [];
                for b = 1:nblocks
                       ImgF2=output_warped(ImgF(:,:,blocks(b,:)),tform,dorsalMaps);
                       imgFwarped = cat(3, imgFwarped, ImgF2);
                end
                clear ImgF ImgF2
                ImgF = imgFwarped;
                clear imgFwarped
                %ImgF2=output_warped(ImgF(:,:,1:floor(size(ImgF,3)/2)),tform,dorsalMaps);
                %ImgF=output_warped(ImgF(:,:,floor(size(ImgF,3)/2)+1:end),tform,dorsalMaps);
                %ImgF = cat(3, ImgF2, ImgF);
            end
            end


            



        else
            'I dont know what kind of data this is'
            
        end

        if params.ImgF_processing.badFramesNaN
            badFrames = setdiff(1:size(ImgF,3), [goodFrames{:}]);
            ImgF(:,:,badFrames) = nan;
        end


        %reshape ImgF to 2D raster
        ImgF = reshape(ImgF, subject_json.init.height*subject_json.init.width, size(ImgF,3));

        if params.ImgF_processing.remove_masked_pixels
            [~, validPixels] = load_standard_mask(params.ImgF_processing);
            ImgF = ImgF(validPixels,:);
        end


        %zscore each pixel
        if params.ImgF_processing.zscore
            ImgF = nanzscore(ImgF')';

        end
    end



    subject_json = update_json(subject_json, true, struct(step = 'loading', type = '', message = 'success!'));
    save_json(subject_json, params)

% catch ME
%     subject_json = update_json(subject_json, false, struct(step = 'loading', type = '', message = ME));
%     save_json(subject_json, params)
% end

end
