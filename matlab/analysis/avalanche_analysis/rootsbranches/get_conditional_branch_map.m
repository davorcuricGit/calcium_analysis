function [termination_weighted_maps, activation_weighted_maps,numactivations] = get_conditional_branch_map(avstats,validPixels,subnetworksFOV, allen_subnets, params)

sz = params.sz;

avstats = get_root_centroids(avstats,validPixels, params.sz);
avstats = get_avcentroid_roilabel(avstats, subnetworksFOV);

T = struct2table(avstats);
T = T(T.merge_flag == 0,:);
T = T(T.rootsubnet ~= 0,:);
%T = T(T.duration > 1,:);

termination_weighted_maps = zeros(sz(1),sz(2),64);
activation_weighted_maps = zeros(sz(1),sz(2),64);
numactivations = zeros(1,64);
for r = 1:height(allen_subnets)
    %get the 
    idx = find(T.rootsubnet == allen_subnets.roi(r));
    numactivations(r) = length(idx);
    for ii = 1:length(idx)
        branch = T.branches(idx(ii)) ;
        
        %count total number of pixels in termination
        temp = zeros(size(validPixels));
        temp(branch{1}) = 1;
        termination_weighted_maps(:,:,r) = termination_weighted_maps(:,:,r) + embeddIntoFOV(temp, validPixels, [128 128]);

        %count only per activation(e.g., each termination should contribute
        %a total of 1 so divide by total number of pixels in termination)
        temp = zeros(size(validPixels));
        temp(branch{1}) = 1/length(branch{1});
        activation_weighted_maps(:,:,r) = activation_weighted_maps(:,:,r) + embeddIntoFOV(temp, validPixels, [128 128]);

    end
end
end
