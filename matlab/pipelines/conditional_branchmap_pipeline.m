

function [subject_json,flag,ME] = conditional_branchmap_pipeline(subject_json, params, project)

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
            step_params.numAvs = length(avstats);

            %get allen subnetworks
            allen_subnets = readtable(fullfile(params.calcium_analysis_root, params.allen_subnets));

            %get the per-subject subnetworks
            [subnetwork, subnetworksFOV] = get_allen_subnetworks(subject_json, params.dorsalMaps, ...
                downsample = subject_json.(params.needs).downsample, ...
                globalmask = project.ImgF_processing.mask_name);

            %get valid Pixels
            [~, validPixels, ~] = load_standard_mask(project.ImgF_processing);
            [~,validPixels,~] = spatial_downsample_reshaped(validPixels, ...
                subject_json.(params.needs).downsample, ...
                struct(mask_name = project.ImgF_processing.mask_name) ...
                );


            'Calculating Conditional Branch Maps....'
            flag = '';
            ME = [];
            conditionalmaps =[];

            [term_map,act_map, num_activations] = get_conditional_branch_map(avstats,validPixels,subnetworksFOV,allen_subnets, step_params);

            'saving maps...'
            step_params.type = 'term_map';
            subject_json = update_json_new(subject_json, true, step_params);
            [subject_json,ME] = save_derivative(subject_json,single(term_map), step_params, project);

            step_params.type = 'act_map';
            subject_json = update_json_new(subject_json, true, step_params);
            [subject_json,ME] = save_derivative(subject_json,single(act_map), step_params, project);

            step_params.type = 'num_activations';
            subject_json = update_json_new(subject_json, true, step_params);
            [subject_json,ME] = save_derivative(subject_json,single(num_activations), step_params, project);

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
