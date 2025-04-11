

function avalanche_pipeline(params)


flag = init_analysis(params);


project_root = params.project_root;
subject_jsons = dir([project_root '/derivatives/metadata/' params.dataset '/**/*.json']);



%%

%load mask and get network
[mask, validPixels] = load_standard_mask(params);
[adjmat,network] = distance_network(128,validPixels, params);


for i = 1:length(subject_jsons)
    ['iexp=' num2str(i)]

    %get the json file
    row = subject_jsons(i);
    json = fileread([row.folder '/' row.name]);
    json = jsondecode(json);

    %set loading parameters. This can also be specified outside for looping
    %through projects.
    if ~exist('params', 'var')
        params = struct(err = 0,...
            warp = 1, ...
            batch_blocks = 4, ...
            tStep = 2000, ...
            down_sample = 2, ...
            thresh_list = [3]);
    end

    %get recording
    try
        %get motion periods
        [segs, goodFrames] = get_segments_to_keep(json, params);
        ImgF = get_calcium_recording(json, params);

    catch ME
        ME
        json = update_json(json, false, struct(step = 'loading', type = '', message = ['iexp=' num2str(i) 'loadingfailed']));
        continue
    end

    %downsample the FOV
    ImgF = spatialBlockDownsample(ImgF, params.down_sample);
    ImgF = zscore_independent(ImgF);

    %filter good frames and get badframes
    goodFrames = [goodFrames(cellfun(@length, goodFrames) > params.good_frames_thresh)];
    badFrames = setdiff(1:size(ImgF,3), [goodFrames{:}]);

    %set badframes to zero
    ImgF(:,:,badFrames) = 0;

    %reshape ImgF;
    ImgF = reshape(ImgF, size(ImgF,1)*size(ImgF,2), size(ImgF,3));

    %keep only valid pixels
    ImgF = ImgF(validPixels,:);

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
        json = update_json(json, true, stepparams);
        json = save_avalanche_derivative(json,avstats, stepparams);

        save_json(json)
        'saved!'
        clear stepparams
    end
    clear ImgF 
    
    %save progress
    progress.iexp = i;
    progress.total = length(subject_jsons);
    progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    save([params.project 'progress'], 'progress');
end
%%
end

