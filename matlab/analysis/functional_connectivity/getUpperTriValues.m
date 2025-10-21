
function trimat = getUpperTriValues(mat)
trimask = ones(size(mat));
trimask = triu(trimask,1);
trimask = find(trimask == 1);
trimat = mat(trimask);
end