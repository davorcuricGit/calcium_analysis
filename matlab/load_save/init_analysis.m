function flag = init_analysis(params)
try
    for p = params.paths_to_add'
        addpath(genpath(fullfile(params.calcium_analysis_root, p{1})))
    end
    for p = params.files_to_load'
        load(fullfile(params.calcium_analysis_root, p{1}));
    end
    flag = 'success!';
catch ME
    flag = ME;
end
end