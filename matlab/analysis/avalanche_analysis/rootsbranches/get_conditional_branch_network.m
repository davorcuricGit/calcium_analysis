function [nodes, edges, ME] = get_conditional_branch_network(subject_json, params, project)
ME = [];
try
    %get the conditional branch maps
    dmeta = subject_json.(params.needs).(params.type);
    derivative = get_needed_derivative(dmeta, subject_json, project);

    %get the number of avalanches
    dmeta = subject_json.(params.needs).(params.type_aux);
    numavs = get_needed_derivative(dmeta, subject_json, project);

    %get allen subnetworks
    allen_subnets = readtable(fullfile(params.calcium_analysis_root, params.allen_subnets));

    %get the per-subject subnetworks
    [subnetwork, subnetworksFOV] = get_allen_subnetworks(subject_json, params.dorsalMaps, ...
        downsample = subject_json.(params.needs).(params.type).downsample, ...
        globalmask = project.ImgF_processing.mask_name);

    %get node positions
    [xPositions, yPositions] = get_allen_centroids(subnetworksFOV);

    %get allen area
    [area] = get_allen_area(subnetworksFOV);


    Adj = zeros(height(allen_subnets), height(allen_subnets));
    for i = 1:height(allen_subnets)
        f = derivative(:,:,i);
        for j = 1:height(allen_subnets)
            idx = find(subnetworksFOV == j);
            Adj(i,j) = sum(sum(f(idx)));
        end
    end

    G = digraph(Adj, allen_subnets.labels);%, 'Xdata', xPositions, 'YData', yPositions);

    nodes = table();
    nodes(:,'names') = allen_subnets.labels;
    nodes(:,'posx') =  num2cell(xPositions);
    nodes(:,'posy') =  num2cell(yPositions);
    nodes(:, 'area') =num2cell(area);
    nodes(:, 'activations') = num2cell(numavs');

    edges = table();
    edges(:,'source') = G.Edges.EndNodes(:,1);
    edges(:,'target') = G.Edges.EndNodes(:,2);
    edges(:, 'weight') = num2cell(G.Edges.Weight);
catch ME
end
end