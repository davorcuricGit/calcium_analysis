

function [flag,ME, avstats] = avalanche_pipeline(ImgF, subject_json, params, project)
avstats = [];
ME = [];%error handeling
progress.iexp = subject_json.init.recid;
progress.total = length(subject_json);

if ~isempty(ImgF)
    try
        if params.run

            

            if isfield(params.ImgF_processing, 'down_sample')
                if params.ImgF_processing.down_sample > 1


                    [ImgF, validPixels, sz] = spatial_downsample_reshaped(ImgF, params.ImgF_processing.down_sample, params.ImgF_processing);
                else
                    [~, validPixels, sz] = load_standard_mask(params.ImgF_processing);
                end
            else
                [~, validPixels, sz] = load_standard_mask(params.ImgF_processing);
            end

            %zscore
            ImgF = nanzscore(ImgF')';


            [adjmat,network] = distance_network(sz(1),validPixels, params.parameters);

            %remove bad drames and bad pixels
            trace = nansum(ImgF);
            badFrames = find(trace == 0);
            ImgF(:,badFrames) = 0;
            bad_pixels = find(nansum(ImgF') == 0);
            ImgF(bad_pixels, :) = 0;

            



            %get avalanches
            %for th = 1:length(params.parameters.thresh_list)
            thresh = params.parameters.threshold;

            %                 step = ['avs_thresh_' num2str(thresh)];
            %                 type = 'avalanches';
            stepparams = struct(step = params.step, ...
                type = params.type, ...
                threshold = thresh, ...
                hkradius = params.parameters.hkradius, ...
                downsample = params.ImgF_processing.down_sample, ...
                warp = project.raw_parameters.warp);

            'Calculating Avalanches....'
            [avstats,ME] = segmented_avalanche_analysis(ImgF, validPixels, adjmat, network, stepparams);
            subject_json = update_json(subject_json, true, stepparams);
            subject_json = save_avalanche_derivative(subject_json,avstats, stepparams, project);

            save_json(subject_json, project)
            'saved!'
            %   clear stepparams
            %end
            %clear ImgF

            %save progress

            progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
            save(fullfile(params.calcium_analysis_root, [subject_json.init.dataset, 'progress.mat']), 'progress');
            %end
            flag = "finished!";
        else
            flag = "project run is off";
        end

    catch ME
        
        flag = 'something went wrong';
        
        progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        progress.ME = ME;
        save(fullfile(params.calcium_analysis_root, [subject_json.init.dataset, 'error.mat']), 'progress');

    end
else
    flag = ['imgF is empty'];
    progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    progress.flag = flag;
    save(fullfile(params.calcium_analysis_root, 'progress', [subject_json.init.dataset, 'error.mat']), 'progress');


end

end

