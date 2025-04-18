
function labeledFrame = labelSingleFrame(clusters, Ncells)

labeledFrame = zeros(1, Ncells);

for i = 1:length(clusters)
    labeledFrame(clusters{i}) = i;
end


end
