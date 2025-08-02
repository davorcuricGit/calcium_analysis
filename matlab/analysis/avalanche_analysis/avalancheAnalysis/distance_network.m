function [A,edge_list] = distance_network(N,validPixels,hkradius)
% Parameters
%N Size of the grid (N x N)
%R Radius

% Generate grid coordinates
[x, y] = meshgrid(1:N, 1:N);
coords = [x(:), y(:)];

% Compute pairwise distances using pdist
distances = pdist(coords, 'euclidean');

% Convert distances to a square matrix
distanceMatrix = squareform(distances);

% Create adjacency matrix based on the radius R
A = distanceMatrix <= hkradius;

% Ensure diagonal elements are zero (no self-loops)
A(1:size(A, 1) + 1:end) = 0;
A = single(A(validPixels, validPixels));



for i = 1:size(A,1)
    edge_list{i} = single(find(A(i,:) == 1));
    edge_list{i} = [edge_list{i} i];
end

end

