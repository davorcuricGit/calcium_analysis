function [subnetwork, indiv_mask] = get_subnetworks(json, dorsalMaps, varargin)
%get the subnetworks absed off of the subejcts individual mask. 
%individual mask is affine warped in the same way as reocrding.
%if a global mask is provided then it will filter any pixels not int he
%globalmask


i_p = inputParser;
i_p.addRequired('json', @isstruct);
i_p.addRequired('dorsalMaps', @isstruct);
i_p.addOptional('downsample', 1);
i_p.addOptional('globalmask', @isstring);
% 
% 
i_p.parse(json, dorsalMaps, varargin{:});


     indiv_mask = load_individual_mask(i_p.Results.json, i_p.Results.dorsalMaps);

        if i_p.Results.downsample > 1
            indiv_mask = spatialBlockDownsample(indiv_mask,i_p.Results.downsample, false);
            clear params
        end

        if ~isempty(i_p.Results.globalmask)
            params.mask_name = i_p.Results.globalmask;
            global_mask = load_standard_mask(params);

            if i_p.Results.downsample > 1
            
            global_mask = spatialBlockDownsample(global_mask,i_p.Results.downsample, false);

            end
            clear params
            indiv_mask = indiv_mask.*global_mask;
        end


    %remove any nonint pixels from the downsampling
    intmask = indiv_mask == floor(indiv_mask);
    indiv_mask = indiv_mask.*intmask;

    

    uq = unique(ceil((indiv_mask(indiv_mask ~= 0))));
    subnetwork = {};
    for i = 1:length(uq)
        subnetwork{i} = find(indiv_mask == uq(i));
    end
end


