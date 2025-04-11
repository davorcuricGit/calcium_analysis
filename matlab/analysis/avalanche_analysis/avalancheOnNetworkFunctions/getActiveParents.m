
function activeParents = getActiveParents(pix, active, network)
%this gets the parents of a current pixel
%same as get active neighbour, made seperate just for code clarity sake tho.
activeParents = getActiveNeighbours(pix, active, network);
end
