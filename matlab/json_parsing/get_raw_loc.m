
function recording_path = get_raw_loc(json, params)
    recording_path = fullfile(params.project_root, params.structure.raw_data, json.init.raw_path, [json.init.name, '.raw']);
end