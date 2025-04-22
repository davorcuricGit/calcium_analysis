
function avstats = get_centroid_roilabel(avstats,subnetworksFOV)

for i = 1:length(avstats)
    centroid_subnet{1,i} = subnetworksFOV(avstats(i).rootcentroid);

end
[avstats.rootsubnet] = centroid_subnet{:};

end