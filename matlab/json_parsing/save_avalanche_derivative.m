function json = save_avalanche_derivative(json,derivative, params)
    try 
    path = fullfile(json.init.project_root, 'derivatives', strrep(json.init.raw_path, 'raw_data', ''));
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
