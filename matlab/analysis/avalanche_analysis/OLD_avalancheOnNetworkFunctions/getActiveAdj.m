
function reducedA = getActiveAdj(active, adjmat, Ncell)
%get adjmat of only the active elements

% for i = 1:length(active)
%     pix = active(i);
%     neighbours = find(adjmat(pix, :) == 1);
%     activeNeighs = intersect(active, neighbours);
%     [~,idx] = intersect(active,activeNeighs,'stable');
%     reducedA(i, idx) = 1;
% end

reducedA = adjmat(active, active);
%these next two steps are needed to get the clusters in another step
reducedA = reducedA - 2*eye(size(reducedA));
reducedA = double(reducedA);

end
