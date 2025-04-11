
function  parentcluster = getActiveParentCluster(cluster,  active, network)
%this gets the active parents of a cluster
parentcluster = [];
for i = 1:length(cluster)
    %parentcluster = [parentcluster  getActiveNeighbours(cluster(i), active, [network{cluster(i)}])'];
    
    
    parentcluster = [parentcluster  getActiveNeighbours(active, [network{cluster(i)}])'];
    
end

end
