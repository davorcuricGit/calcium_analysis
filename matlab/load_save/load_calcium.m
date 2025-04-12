function [ImgF, segs, goodFrames, subject_json, ME] = load_calcium(subject_json, params)

%set loading parameters. This can also be specified outside for looping
%through projects.

ImgF = [];
segs = [];
goodFrames = [];

if ~exist('params', 'var')
    params = struct(err = 0,...
        warp = 1, ...
        batch_blocks = 4, ...
        tStep = 2000, ...
        down_sample = 2 ...
        );
end

%get recording
try
    %get motion periods
    [segs, goodFrames] = get_segments_to_keep(subject_json, params);

    %get the raw recording
    if isfield(params.raw_parameters, 'tStep')
        if isnumeric(params.raw_parameters.tStep)
            tSteps = params.raw_parameters.tStep;
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


    %update json
    subject_json = update_json(subject_json, false, struct(step = 'loading', type = '', message = 'success!'));
catch ME
    subject_json = update_json(subject_json, true, struct(step = 'loading', type = '', message = ME));
end

end
