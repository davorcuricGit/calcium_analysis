
function [derivative, ME] = load_derivative(json,step, project)
derivative = [];
ME = [];
try


    path = fullfile(project.project_root, project.project_name, project.structure.derivatives, json.init.raw_path);

    floc = fullfile(path, [json.(step).name, json.(step).extension]);
    load(floc)
catch ME
    % if this fails update the json success flag

    dervitative = [];
end
end
