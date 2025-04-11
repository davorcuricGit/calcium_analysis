
function recording_path = get_raw_loc(json)
    recording_path = fullfile(json.init.project_root, 'raw_data', json.init.raw_path, [json.init.name, '.raw']);
end