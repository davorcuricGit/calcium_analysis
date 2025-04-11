
function frame_error = load_frame_errors(json)
    pathname = fullfile(json.init.project_root, 'raw_data', json.processing.frame_error);
    frame_error = load(pathname);
    frame_error = frame_error.error;
end