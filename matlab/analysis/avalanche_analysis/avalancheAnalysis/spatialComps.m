

function comps = spatialComps(S, A)
% spatialComps: return cell array of spatially connected components within S
visited = false(numel(S),1);
maxNode = max(S);
mapInS = false(maxNode,1);
mapInS(S) = true;
comps = {};
for m = 1:numel(S)
    if ~visited(m)
        queue = S(m);
        visited(m) = true;
        comp = S(m);
        ptr = 1;
        while ptr <= numel(queue)
            u = queue(ptr);
            ptr = ptr + 1;
            nbrs = A{u};
            for vi = 1:length(nbrs)
                v = nbrs(vi);
                if v <= maxNode && mapInS(v)
                    j = find(S == v, 1);
                    if ~visited(j)
                        visited(j) = true;
                        queue(end+1) = v;
                        comp(end+1) = v;
                    end
                end
            end
        end
        comps{end+1} = comp;
    end
end
end
