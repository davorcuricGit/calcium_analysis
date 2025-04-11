

function [S, D, merged, labeledAvalanches, roots, rootTimes, branches] = getAvalanches(state, network, adjmat, ~, t0)

%labels avalanches according to network

%inputs: 
    %state: NxT binary raster of neuron/glia with activations (N = number of neurons, T = frames)
    %network: N cell array with the i-th entry being the neighbours of neuron i
    %adjmat: NxN adjacency matrix (don't ask why i import both networks)
    %~:  don't worry about it, was for data from optical recordings
    %t0: the time of the first frame, useful for keeping track of when
    %avalanches occur

%outputs:
    %SS: 3 cell of avalanche sizes. SS{1] = all avalanches with single root, SS{2} = all avalanches with multiroot
    %SS{3} is all avalanches (idk why I output this, its just the union of the other two)
    %DD: same as SS but avalanche durations. 
    %labeledAvalanches: NxT matrix similar to raster, but each 1 in the
    %raster is relabeled to its corresponding avalanche.
    %roots: 





Ncells = size(state, 1);
Tmax = size(state, 2);

labeledFrame = single(zeros(Ncells, Tmax));

%first label all the avalanches in frame 1
t = 1;
active{1} = [];
active{1} = find(state(:,t) == 1);
avCount = 1;

activeAdjmat = getActiveAdj([active{1}], adjmat, Ncells);

cluster{t} = getCurrentClusters(active{1}, activeAdjmat, true);
labeledFrame(:,t) = single(labelSingleFrame(cluster{t}, Ncells));
for i = 1:length(cluster{t})
    Av{i} = startAvalanche(i, cluster{t}{i}, t);
end


for t = 2:Tmax;

    active{2} = find(state(:,t) == 1);
    
    if t < Tmax
        active{3} = find(state(:,t+1) == 1);
    else
        active{3} = [];
    end

    if isempty([active{2}]);
        %'finishing early'
        %break;
        continue
    end

    activeAdjmat = getActiveAdj([active{2}], adjmat, Ncells);
    cluster{t} = (getCurrentClusters(active{2}, activeAdjmat, true));

    testlabel = ceil(max(labeledFrame(:,t-1),[], 'all')+1);
    avCount = max(avCount, testlabel);


    [labeledFrame avCount Av] = updateLabels_w_branches(Av, labeledFrame, t, cluster{t}, active{1}, active{3}, network, avCount);


    active{1} = active{2};
    
end

% GET THE ROOTS
labeledAvalanches = labeledFrame;
labeledFrame(labeledFrame == 0) = [];
if ~isrow(labeledFrame); labeledFrame = labeledFrame';end
[S,GR] = groupcounts(labeledFrame');
idx = 1:length(Av);
Av(setdiff(idx, GR)) = [];

S = [];
D = [];
for i = 1:length(Av);
    S(i) = Av{i}.size;
    D(i) = Av{i}.duration;
    merged(i) = Av{i}.merged;
    roots{i} = Av{i}.roots;
    rootTimes{i} = Av{i}.rootTime + t0-1;
    branches{i} = Av{i}.branches;
end

%S1 = S(~merged);
%Sg =  S(merged);
%D1 = D(~merged);
%Dg =  D(merged);

%SS = {S1 Sg S};
%DD = {D1 Dg D};


end

