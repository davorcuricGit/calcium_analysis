function [subject_json,flag,ME, nodes, edges] = sourcesink_pipeline(subject_json, params, project)

avstats = [];
ME = [];

%check that avalanches exist
threshold = params.parameters.threshold;
radius = params.parameters.hkradius;
params.needs = ['conditional_branch_map_radius_' num2str(radius) '_thresh_' num2str(threshold)];%[params.needs num2str(threshold)];

subject_json
params.needs

if ~isfield(subject_json, params.needs)
    ME = 'prereq not yet calculated!';
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
                downsample = subject_json.(params.needs).(params.type).downsample, ...
                sz = [subject_json.init.height, subject_json.init.width]/subject_json.(params.needs).(params.type).downsample, ...
                global_mask = project.ImgF_processing.mask_name, ...
                derivative_extension = '.csv' ...
                );
            
            'Calculating Networks....'
            flag = '';
            ME = [];
            conditionalmaps =[];
            [nodes, edges, ME] = get_conditional_branch_network(subject_json, params, project);

            'saving node and edge list...'
            step_params.type = [params.type '_nodes'];
            subject_json = update_json_new(subject_json, true, step_params);
            [subject_json,ME] = save_derivative(subject_json,nodes, step_params, project);
            
            step_params.type = [params.type '_edges'];
            subject_json = update_json_new(subject_json, true, step_params);
            [subject_json,ME] = save_derivative(subject_json,edges, step_params, project);

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
