

function [subject_json,flag,ME, maps] = root_and_branch_maps_pipeline(subject_json, params, project)

avstats = [];
ME = [];

%check that avalanches exist
threshold = params.parameters.threshold;
params.needs = [params.needs num2str(threshold)];

if ~isfield(subject_json, [params.needs])
    ME = 'avalanches not yet calculated!';
    progress.iexp = subject_json.init.recid;
    progress.total = length(subject_json);
    subject_json = update_json(subject_json, false, struct(step = params.step, type =  params.type, message = ME));
    flag = ME;
else

    try

        subject_json.(params.needs).extension = '.mat';

        ME = [];%error handeling
        progress.iexp = subject_json.init.recid;
        progress.total = length(subject_json);

        if params.run

            step_params = struct(step = params.step, ...
                type = params.type, ...
                threshold = threshold, ...
                hkradius = params.parameters.hkradius, ...
                downsample = subject_json.(params.needs).downsample, ...
                warp = subject_json.(params.needs).warp, ...
                sz = [subject_json.init.height, subject_json.init.width]/subject_json.(params.needs).downsample, ...
                global_mask = project.ImgF_processing.mask_name, ...
                derivative_extension = '.csv' ...
                );

            %Loading avalanches
            [avstats, ME] = load_derivative(subject_json,params.needs, project);

            
            %get valid Pixels
            [~, validPixels, ~] = load_standard_mask(project.ImgF_processing);
            [~,validPixels,~] = spatial_downsample_reshaped(validPixels, ...
                subject_json.(params.needs).downsample, ...
                struct(mask_name = project.ImgF_processing.mask_name) ...
                );


            'Calculating root and Branch Maps....'
            flag = '';
            ME = [];
            maps =[];

            maps = get_rootsbranches_maps(avstats, validPixels, step_params);
 
             'saving maps...'
             step_params.type = 'rootbranch_map';
             subject_json = update_json_new(subject_json, true, step_params);
             [subject_json,ME] = save_derivative(subject_json,maps, step_params, project);

 
             save_json(subject_json, project)
             'saved!'

        else
            flag = "project run is off"
        end


    catch ME
        flag = 'something went wrong'
        progress.time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        progress.ME = ME;
        save(fullfile(params.calcium_analysis_root, [subject_json.init.dataset, 'error.mat']), 'progress');
    end


end
end
