

function  [labeledFrame avCount Av] = updateLabels_w_branches(Av, labeledFrame, currentTime, currentClusters, prevActive, nextActive, network, avCount )

t = currentTime;


for i = 1:length(currentClusters)

    c = [currentClusters{i}];
    %


    %first get the active parents
    parentcluster = getActiveParentCluster(c,  prevActive, network);

    %find active children, same logic as parents
    childrencluster = getActiveParentCluster(c,  nextActive, network);

    %these are the avalanche labels of the parents.
    %parentLabels = sort(unique(labeledFrame(parentcluster,t-1)));
    parentLabels = unique(labeledFrame(parentcluster,t-1));

    if prod(parentLabels) == 0
        stop
    end

    if isempty(parentcluster)
        %no parents, this is the start of a new avalanche


        %
        labeledFrame(c,t) = avCount;
        Av{avCount} = startAvalanche(avCount, c, t);

        if isempty(childrencluster)
            %this cluster is a branch
            Av{avCount}.branches = [Av{avCount}.branches c];
        end

        avCount = avCount + 1;




        %now we need to know if the parents came from one avalanche or more
    elseif length(parentLabels) == 1
        %only one parent
        %apply the parents label to the current cluster
        labeledFrame(c,t) = parentLabels;

        Av{parentLabels} = updateAvalanche_w_branches(Av{parentLabels}, t, length(c));

        if isempty(childrencluster)
            %this cluster is a branch
            Av{parentLabels}.branches = [Av{parentLabels}.branches; reshape(c,[],1)];
        end

    elseif length(parentLabels) > 1
        %more than one parent
        %the avalanche with the smallest label will provide the new labels
        %a minus sign will indicate merging
        newLabel = floor(parentLabels(1));

        %Av{newLabel} = updateAvalanche(Av{newLabel}, t, c);
        Av{newLabel} = updateAvalanche_w_branches(Av{newLabel}, t, length(c));
        Av{newLabel}.merged = true;
        %go back and relabel all the parents
        for parlab = 2:length(parentLabels)



            count = 1;

            pastframe = labeledFrame(:,t-count);
            idx = find(pastframe == parentLabels(parlab));
            Av{newLabel} = updateAvalanche_w_branches(Av{newLabel}, t-count, length(idx));

            clear Z

            %go backwards and label
            while ~isempty(idx)
                labeledFrame(idx,t-count) = newLabel;

                count = count + 1;
                if t - count <= 0; break; end
                pastframe = labeledFrame(:,t-count);
                idx = find(pastframe == parentLabels(parlab));
                %Av{newLabel} = updateAvalanche(Av{newLabel}, t-count, idx');
                Av{newLabel} = updateAvalanche_w_branches(Av{newLabel}, t-count, length(idx));
            end

            %now check the current frame for any missed children nodes
            pastframe = labeledFrame(:,t);
            idx = find(pastframe == parentLabels(parlab));
            labeledFrame(idx,t) = newLabel;
            %Av{newLabel} = updateAvalanche(Av{newLabel}, t, idx);
            Av{newLabel} = updateAvalanche_w_branches(Av{newLabel}, t, length(idx));

            %The roots and branches of the parent avalanches need to be joined
            Av{newLabel}.roots = [Av{newLabel}.roots Av{parentLabels(parlab)}.roots];
            Av{newLabel}.rootTime = [Av{newLabel}.rootTime Av{parentLabels(parlab)}.rootTime];
            Av{newLabel}.branches = [Av{newLabel}.branches; reshape(Av{parentLabels(parlab)}.branches, [], 1)];

            AvLabel{parentLabels(parlab)} = [];

            %labeledFrame(labeledFrame == parentLabels(parlab)) = newLabel;
        end

        %finally apply the label to the current cluster
        labeledFrame(c,t) = newLabel;
    else
        'something unexpected happened but idk what atm'
        stop
    end




end
end
