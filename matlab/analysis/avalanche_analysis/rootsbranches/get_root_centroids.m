


function avstats = get_root_centroids(avstats,validPixels, sz);

clear c
%get the centroid of each root
for i = 1:length(avstats);

    temp = zeros(size(validPixels));
    temp(avstats(i).roots) = 1;
    temp = embeddIntoFOV(temp, validPixels, sz);

    stats = regionprops(temp);
    centroid = arrayfun(@round, stats.Centroid);
    centroid = sub2ind(sz,centroid(2), centroid(1));

    c{1,i} = centroid;
end
[avstats.rootcentroid] = c{:};

end