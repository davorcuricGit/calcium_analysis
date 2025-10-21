function mask = load_individual_mask(json, dorsalMaps);

try
    maskfile= fullfile(json.init.project_root, 'raw_data', strrep(json.processing.transform, json.init.dataset, '') );
    load(maskfile)
catch
    maskfile= fullfile(json.init.project_root,json.init.dataset, 'raw_data', strrep(json.processing.transform, json.init.dataset, '') );
    load(maskfile)

end
mask = output_warped(mask,tform,dorsalMaps);
end