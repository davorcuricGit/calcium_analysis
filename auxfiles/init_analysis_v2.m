function [flag,loaded] = init_analysis_v2(params)

loaded = struct();



try
    for p = params.paths_to_add'
        addpath(genpath(fullfile(params.calcium_analysis_root, p{1})))
    end

    for p = params.files_to_load'
        X = load(fullfile(params.calcium_analysis_root, p{1}));

        % Get the name of the variable in the structure X
        varName = fieldnames(X); % Get the field name(s) in X
        varName = varName{1};    % Assuming there is only one variable in the .mat file

        % Add the variable to the 'loaded' structure
        loaded.(varName) = X.(varName);


    end
    flag = 'success!';
catch ME
    flag = ME;

end
end