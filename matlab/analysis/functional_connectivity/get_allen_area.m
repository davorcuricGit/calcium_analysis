function [area] = get_allen_area(mask)
% Input: NxN matrix 'mask' containing 0s and labeled clusters (1 to M)

% Get the unique cluster labels (excluding 0)
clusterLabels = 1:64;

% Initialize arrays to store centroids
area = zeros(length(clusterLabels), 1);


% Loop through each cluster label
for i = 1:length(clusterLabels)
    % Get the current cluster label
    cluster = clusterLabels(i);
    
    % Find the indices of the current cluster in the mask
    idx = find(mask == cluster);
    
    % Compute the centroid of the cluster
    area(i) = length(idx);
end


end

