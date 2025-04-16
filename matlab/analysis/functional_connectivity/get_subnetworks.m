function subnetwork = get_subnetworks(json, dorsalMaps)
%get the subnetworks absed off of the subejcts individual mask. 
%individual mask is affine warped in the same way as reocrding.
%if a global mask is provided then it will filter any pixels not int he
%globalmask


% i_p = inputParser;
% i_p.addRequired('recording_path', @ischar)
% i_p.addRequired('dorsalMaps', @isstruct);
% 
% 
% i_p.parse(recording_path, dorsalMaps, varargin{:});

% 

     indiv_mask = load_individual_mask(json, dorsalMaps);

    

    uq = unique(ceil((indiv_mask(indiv_mask ~= 0))));
    subnetwork = {};
    for i = 1:length(uq)
        subnetwork{i} = find(indiv_mask == uq(i));
    end
end


