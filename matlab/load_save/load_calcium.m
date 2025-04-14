function [ImgF, segs, goodFrames, badFrames, subject_json, ME] = load_calcium(subject_json, params)

%set loading parameters. This can also be specified outside for looping
%through projects.

ImgF = [];
segs = [];
goodFrames = [];
badFrames = [];

if ~exist('params', 'var')
    params = struct(err = 0,...
        warp = 1, ...
        batch_blocks = 4, ...
        tSteps = 2000, ...
        down_sample = 2 ...
        );
end

%get recording
try
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
        ImgF = F_ReadRAW(recording_path, [h,w, tSteps], subject_json.init.machine_p, params.raw_parameters.warp, params.raw_parameters.err, 0, params.raw_parameters.batch_blocks, params);

         if params.ImgF_processing.zscore
            ImgF = zscore_independent(ImgF);
        end

        if params.ImgF_processing.badFramesNaN
            badFrames = setdiff(1:size(ImgF,3), [goodFrames{:}]);
            ImgF(:,:,badFrames) = nan;
        end

        if params.ImgF_processing.remove_masked_pixels
            [mask, validPixels] = load_standard_mask(params.ImgF_processing);
            params.ImgF_processing.reshape = true; %this requires reshaping
        end

        if params.ImgF_processing.reshape
            ImgF = reshape(ImgF, subject_json.init.height*subject_json.init.width, size(ImgF,3));
            if params.ImgF_processing.remove_masked_pixels
                ImgF = ImgF(validPixels,:);
            end
        end

       

        subject_json = update_json(subject_json, true, struct(step = 'loading', type = '', message = 'success!'));
        save_json(subject_json, params)
    end
catch ME
    subject_json = update_json(subject_json, false, struct(step = 'loading', type = '', message = ME));
    save_json(subject_json, params)
end

end
