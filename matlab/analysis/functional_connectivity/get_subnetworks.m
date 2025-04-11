function subnetwork = get_subnetworks(json, dorsalMaps, varargin)
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
recording_path = fullfile(json.init.project_root, 'raw_data', strrep(json.processing.transform, 'transform.mat', '')) ;
     indiv_mask = get_individual_mask(recording_path, dorsalMaps);
%     
%     if ~isempty(i_p.Results.global_mask)
%         %indiv_mask = indiv_mask.*i_p.Results.global_mask;
%         indiv_mask = reshape(indiv_mask, prod(size(indiv_mask)), 1);
%         indiv_mask = indiv_mask(find(i_p.Results.global_mask == 1));
%         
%     end
    
    %remove boundary
    

    uq = unique(ceil((indiv_mask(indiv_mask ~= 0))));
    subnetwork = {};
    for i = 1:length(uq)
        subnetwork{i} = find(indiv_mask == uq(i));
    end
end


