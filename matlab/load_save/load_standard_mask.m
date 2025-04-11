function [mask, validPixels] = get_standard_mask(params)

    %get the mask and validPixels
       
    mask = load(fullfile(params.calcium_analysis_root, 'matlab_codes', 'load_save', params.mask_name));
    f = fieldnames(mask);
    mask = mask.(f{1});


    maxmask = max(max(mask));
    mask = single(mask/maxmask);
    
    mask = spatialBlockDownsample(mask, params.down_sample);
    mask(mask ~= 1) = NaN;
    validPixels = single(find(mask == 1));
    
end

