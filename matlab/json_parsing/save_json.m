
function save_json(json)
    %
    save_dir = fullfile(json.init.project_root, 'derivatives', 'metadata', strrep(json.init.raw_path, '/raw_data/', ''));
    save_name = fullfile(save_dir, [json.init.uniqueid, '.json']);
    json_text = jsonencode(json);
    fid = fopen(save_name, 'w');
    fwrite(fid, json_text, 'char');
    fclose(fid);
end
