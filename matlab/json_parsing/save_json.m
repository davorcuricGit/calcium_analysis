
function save_json(json, project)
    %
    save_dir = fullfile(project.project_root, project.project_name, project.structure.metadata, json.init.raw_path);
    if ~isfolder(save_dir)
        'something very seriously went wrong this should not be possible'
        'this is serious enough that I am going to stop this'
        ".json file should not be able to exist withou tthe directory existing"
        stop
    end
    save_name = fullfile(save_dir, [json.init.uniqueid, '.json']);
    json_text = jsonencode(json);
    fid = fopen(save_name, 'w');
    fwrite(fid, json_text, 'char');
    fclose(fid);
end
