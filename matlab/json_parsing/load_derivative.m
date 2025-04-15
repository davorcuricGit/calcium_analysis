
function derivative = load_derivative(json,step, project)
derivative = [];
try


    path = fullfile(project.project_root, project.project_name, project.structure.derivatives, json.init.raw_path);

    floc = fullfile(path, [json.(step).name, json.(step).extension]);
    load(floc)
catch
    % if this fails update the json success flag

    dervitative = [];
end
end
