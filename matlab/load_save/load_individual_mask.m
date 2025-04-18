function mask = load_individual_mask(json, dorsalMaps);
maskfile= fullfile(json.init.project_root, 'raw_data', strrep(json.processing.transform, json.init.dataset, '') );
load(maskfile)
mask = output_warped(mask,tform,dorsalMaps);
end