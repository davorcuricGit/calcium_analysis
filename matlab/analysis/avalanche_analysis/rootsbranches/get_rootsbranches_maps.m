
function Z = get_rootsbranches_maps(avstats, validPixels, params);

sz = params.sz;
rootmap = zeros(sz);
branchmap = zeros(sz);
for i = 1:length(avstats)
    temp = zeros(size(validPixels));
    temp([avstats(i).roots]) = 1;
    rootmap = rootmap + embeddIntoFOV(temp, validPixels, sz);

    temp = zeros(size(validPixels));
    temp([avstats(i).branches]) = 1;
    branchmap = branchmap + embeddIntoFOV(temp, validPixels, sz);
end

rootmap = reshape(rootmap, prod(sz),1);
branchmap = reshape(branchmap, prod(sz),1);

rootmap = rootmap(validPixels);
branchmap = branchmap(validPixels);

Z = [rootmap'; branchmap'; validPixels'];

end

