function [xPositions, yPositions] = get_allen_centroids(mask)
% Input: NxN matrix 'mask' containing 0s and labeled clusters (1 to M)

% Get the unique cluster labels (excluding 0)
clusterLabels = 1:64;

% Initialize arrays to store centroids
xPositions = zeros(length(clusterLabels), 1);
yPositions = zeros(length(clusterLabels), 1);

% Loop through each cluster label
for i = 1:length(clusterLabels)
    % Get the current cluster label
    cluster = clusterLabels(i);
    
    % Find the indices of the current cluster in the mask
    [rows, cols] = find(mask == cluster);
    
    % Compute the centroid of the cluster
    xPositions(i) = mean(cols); % Mean of column indices (x-coordinates)
    yPositions(i) = mean(rows); % Mean of row indices (y-coordinates)
end


end

