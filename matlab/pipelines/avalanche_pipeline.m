

function flag = avalanche_pipeline(ImgF, subject_json, params)


if params.run

    if isfield(params.ImgF_processing, 'down_sample')
        if params.ImgF_processing.down_sample > 1
            'here'
            [ImgF, validPixels, sz] = spatial_downsample_reshaped(ImgF, params.ImgF_processing);
        else
            [~, validPixels, sz] = load_standard_mask(params.ImgF_processing);
        end
    else
        [~, validPixels, sz] = load_standard_mask(params.ImgF_processing);
    end

    [adjmat,network] = distance_network(sz(1),validPixels, params.parameters);


    trace = sum(ImgF);
    badFrames = find(isnan(trace) == 1);
    ImgF(:,badFrames) = 0;
    imagesc(ImgF)
    stop


    %get avalanches
    for th = 1:length(params.thresh_list)
        thresh = params.thresh_list(th);

        step = ['avs_thresh_' num2str(thresh)];
        type = 'avalanches';
        stepparams = struct(step = step, ...
            type = type, ...
            threshold = thresh, ...
            hkradius = params.hkradius, ...
            downsample = params.down_sample, ...
            good_frames_threshold = params.good_frames_thresh, ...
            warp = params.warp);

        avstats = segmented_avalanche_analysis(ImgF, validPixels, adjmat, network, stepparams);
        subject_json = update_subject_json(subject_json, true, stepparams);
        subject_json = save_avalanche_derivative(subject_json,avstats, stepparams);

        save_json(subject_json)
        'saved!'
        clear stepparams
    end
    clear ImgF

    %save progress
    progress.iexp = i;
    progress.total = length(subject_subject_jsons);
    progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    save([params.project 'progress'], 'progress');
    %end
    flag = "finished!";
else
    flag = "project run is off";
end
%%
end

