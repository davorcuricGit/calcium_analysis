

function clusters = getClusterStats(X, A)
[N, T] = size(X);
allLabels = unique(X(:));
allLabels(allLabels==0) = [];
K = numel(allLabels);

clusters = struct(...
    'id',         cell(1,K), ...
    'size',       cell(1,K), ...
    'duration',   cell(1,K), ...
    'start_time', cell(1,K), ...
    'roots',      cell(1,K), ...
    'branches',   cell(1,K), ...
    'merge_flag', cell(1,K)  ...
    );

for idx = 1:K
    k = allLabels(idx);
    clusters(idx).id = k;

    % Collect all occurrences
    [nodes, times] = find(X == k);
    clusters(idx).size = numel(nodes);
    t0 = min(times);
    t1 = max(times);
    clusters(idx).start_time = t0;
    clusters(idx).duration   = t1 - t0 + 1;

    % --- Roots at t0 ---
    S0 = nodes(times == t0);
    comps0 = spatialComps(S0, A);
    roots = [];
    for c = comps0
        comp = c{1}; hasParent = false;
        if t0 > 1
            for u = comp'
                nbrs = A{u};
                for vi = 1:length(nbrs)
                    v = nbrs(vi);
                    if X(v, t0-1) == k
                        hasParent = true;
                        break;
                    end
                end
                if hasParent, break; end
            end
        end
        if ~hasParent
            roots = [roots; comp(:)];
        end
    end
    clusters(idx).roots = unique(roots);

    % --- Branches at t1 ---
    S1 = nodes(times == t1);
    comps1 = spatialComps(S1, A);
    branches = [];
    for c = comps1
        comp = c{1}; hasChild = false;
        if t1 < T
            for u = comp'
                nbrs = A{u};
                for vi = 1:length(nbrs)
                    v = nbrs(vi);
                    if X(v, t1+1) == k
                        hasChild = true;
                        break;
                    end
                end
                if hasChild, break; end
            end
        end
        if ~hasChild
            branches = [branches; comp(:)];
        end
    end
    clusters(idx).branches = unique(branches);

    % --- Merge flag detection ---
    mf = false;
    for tt = t0+1 : t1
        Sp = nodes(times == tt-1);
        compsP = spatialComps(Sp, A);
        touched = false(numel(compsP),1);
        for cp = 1:numel(compsP)
            comp = compsP{cp};
            for u = comp'
                nbrs = A{u};
                for vi = 1:length(nbrs)
                    v = nbrs(vi);
                    if X(v, tt) == k
                        touched(cp) = true;
                        break;
                    end
                end
                if touched(cp), break; end
            end
        end
        if sum(touched) > 1
            mf = true;
            break;
        end
    end
    clusters(idx).merge_flag = mf;
end
end