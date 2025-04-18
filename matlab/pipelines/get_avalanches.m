
function [all_clusters,flag, ME] = get_avalanches(ImgF, subject_json, av_json, project)

all_clusters = [];
ME = [];%error handeling
flag = 'fail';
progress.iexp = subject_json.init.recid;
progress.total = length(subject_json);


thresh = av_json.parameters.threshold;


stepparams = struct(step = av_json.step, ...
    type = av_json.type, ...
    threshold = thresh, ...
    hkradius = av_json.parameters.hkradius, ...
    downsample = av_json.ImgF_processing.down_sample, ...
    warp = project.raw_parameters.warp);

if ~isempty(ImgF)
    try
        if av_json.run
            %prep the recording by downsampling, removing bad frames,
            [ImgF, validPixels, sz] = spatial_downsample_reshaped(ImgF, av_json.ImgF_processing.down_sample, av_json.ImgF_processing);

            ImgF = nanzscore(ImgF')';

            %remove bad drames and bad pixels
            trace = nansum(ImgF);
            badFrames = find(trace == 0);
            ImgF(:,badFrames) = 0;
            bad_pixels = find(nansum(ImgF') == 0);
            ImgF(bad_pixels, :) = 0;

            ImgF = ImgF > av_json.parameters.threshold;

            goodFrames = get_non_zero_segments(nansum(ImgF));
            
            %back to volume
            ImgF = embeddIntoFOV(ImgF, validPixels, sz);
            mask = embeddIntoFOV(validPixels, validPixels, sz);
            mask = mask > 0;
            
            


            %get the network
            [~,network] = distance_network(sz(1),validPixels, av_json.parameters);


            %for each segment of the recording find clusters
            SE = get_strel_dist(av_json.parameters.hkradius);
            all_clusters = [];
            next_id_offset = 0;
            for s = 1:length(goodFrames)
                % 1) dilate each frame
                f = imdilate(ImgF(:,:,goodFrames{s}), strel('disk', av_json.parameters.hkradius));
                f = f.*mask;

                % 2) label clusters

                CC = bwconncomp(f, 6);
                labels3D = labelmatrix(CC);     % H×W×T of cluster IDs
                labeled = labels3D.*uint8(ImgF(:,:,goodFrames{s})); %remove the dilation
                labeled = reshape(labeled, prod(sz), length(goodFrames{s}));
                labeled = labeled(validPixels, :);

                clusters = getClusterStats(labeled, network);

                % Offset IDs to avoid label collisions as well as starttimes
                for i = 1:numel(clusters)
                    clusters(i).id = clusters(i).id + next_id_offset;
                    clusters(i).start_time = clusters(i).start_time + goodFrames{s}(1);
                end

                all_clusters = [all_clusters, clusters];
                next_id_offset = max([all_clusters.id]);
            end
            
            %save derivative and update json
            subject_json = update_json(subject_json, true, stepparams);
            subject_json = save_avalanche_derivative(subject_json,all_clusters, stepparams, project);

            save_json(subject_json, project)
        
            flag = 'success!'
        else
            flag = "project run is off"
        end


    catch ME

        flag = 'something went wrong';

        progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        progress.ME = ME;
        save(fullfile(av_json.calcium_analysis_root, [subject_json.init.dataset, 'error.mat']), 'progress');

    end
else
    flag = ['imgF is empty'];
    progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    progress.flag = flag;
    save(fullfile(av_json.calcium_analysis_root, 'progress', [subject_json.init.dataset, 'error.mat']), 'progress');


end

end


