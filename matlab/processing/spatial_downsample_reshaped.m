function [ImgF, validPixels] = spatial_downsample_reshaped(ImgF, params)
%this takes in a NxT raster and downsamples it spatially

[mask, validPixels] = load_standard_mask(params);

down_sample = params.down_sample;
vpFOV = embeddIntoFOV(validPixels, validPixels, size(mask));
vpFOV(1:down_sample:end, :)=0;
vpFOV(:, 1:down_sample:end) = 0;
cgvp = find(vpFOV ~= 0);

[~, idx] = ismember(cgvp, validPixels);
vpFOV(1:down_sample:end, :)=[];
vpFOV(:, 1:down_sample:end) = [];
cgvp = find(vpFOV ~= 0);
ImgF = ImgF(idx,:);


end