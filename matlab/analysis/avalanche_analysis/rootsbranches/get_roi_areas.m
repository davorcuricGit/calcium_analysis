function get_roi_areas(subnetworksFOV, allen_subnets)
for i = 1:height(allen_subnets)
    area(i) = length(find(subnetworksFOV == allen_subnets.roi(i)));
end
end