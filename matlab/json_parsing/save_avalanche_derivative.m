function json = save_avalanche_derivative(json,derivative, params, project)
    try 
    path = fullfile(project.project_root, project.project_name, project.structure.derivatives, json.init.raw_path);
    
    if ~isfolder(path)
        mkdir(path)
    end
    
    floc = fullfile(path, [json.(params.step).name, '.mat']);
    save(floc, 'derivative')
    catch
        % if this fails update the json success flag
        json.(params.step).success = 0;
    end
end
