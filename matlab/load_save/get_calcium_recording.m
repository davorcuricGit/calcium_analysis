
function ImgF = get_calcium_recording(json, params)
    %load the calcium recording
    %load partial recording if tStep is specifed in params

    if isfield(params, 'tStep')
        if isnumeric(params.tStep)
            tSteps = params.tStep;
        else
            tSteps = json.init.duration;
        end
    else
        tSteps = json.init.duration;
    end
        

    h = json.init.height;
    w = json.init.width;
    %recording_path = fullfile(json.init.project_root, 'raw_data', json.init.raw_path, [json.init.name, '.raw']);
    recording_path = get_raw_loc(json);
    ImgF = F_ReadRAW(recording_path, [h,w, tSteps], json.init.machine_p, params.warp, params.err, 0, params.batch_blocks, params);
end