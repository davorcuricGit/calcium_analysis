
function  cluster = getCurrentClusters(active, activeAdjmat, absoluteNode)
%if absoluteNode is true then I want to use the actual node from the
%original graph, otherwise it is a relative index with resepct to the
%activeadjmat matrix. If it is false then the active input can be set to
%empty

%clusters will be defined from the adjacency matrix
[pp,qq,rr,ss] = dmperm(activeAdjmat);



for i = 1:length(rr)-1
    if absoluteNode
        cluster{i} = active(pp(rr(i):rr(i+1) - 1));
    else
        cluster{i} = (pp(rr(i):rr(i+1) - 1));
    end
end

cluster{i} = single(cluster{i});

end
