
function avstats = get_avcentroid_roilabel(avstats,subnetworksFOV)
%this function should be renamed to reflect that it is for avalanche
%clusters
for i = 1:length(avstats)
    centroid_subnet{1,i} = subnetworksFOV(avstats(i).rootcentroid);

end
[avstats.rootsubnet] = centroid_subnet{:};

end