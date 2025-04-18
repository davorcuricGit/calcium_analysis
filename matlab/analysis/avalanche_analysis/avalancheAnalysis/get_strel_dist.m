function SE = get_strel_dist(radius)
% 1) Build the 3‑slice structuring element for spatiotemporal connectivity
R    = radius;                       % your disk radius
disk = strel('disk', R).Neighborhood;  % 2D disk
SE   = false(size(disk,1), size(disk,2), 3);
SE(:,:,2)         = disk;       % spatial links within same time
mid               = ceil(size(disk)/2);
SE(mid(1),mid(2),[1 3]) = 1;    % temporal links forward/back

end