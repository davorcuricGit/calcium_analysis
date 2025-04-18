function [ImgF, cgvp, sz] = spatial_downsample_reshaped(ImgF,down_sample, params)
%this takes in a NxT raster and downsamples it spatially

[mask, validPixels] = load_standard_mask(params);

%down_sample = params.down_sample;
vpFOV = embeddIntoFOV(validPixels, validPixels, size(mask));

% %I'm doing it this way to keep code consistent with previous codes where
%we keep pixels starting from 1:ds:end
temp = zeros(size(mask));
temp(1:down_sample:end, 1:down_sample:end) = 1;

vpFOV = vpFOV.*temp;
%vpFOV(1:down_sample:end, 1:down_sample:end) = 0;
%vpFOV(1:down_sample:end, :)=0;
%vpFOV(:, 1:down_sample:end) = 0;
cgvp = find(vpFOV ~= 0);
% 

[~, idx] = ismember(cgvp, validPixels);

vpFOV = spatialBlockDownsample(vpFOV, 2, false);

% vpFOV(1:down_sample:end, :)=[];
% vpFOV(:, 1:down_sample:end) = [];
% %vpFOV(1:down_sample:end, 1:down_sample:end) = [];
cgvp = find(vpFOV ~= 0);

ImgF = ImgF(idx,:);
sz = size(vpFOV);

end