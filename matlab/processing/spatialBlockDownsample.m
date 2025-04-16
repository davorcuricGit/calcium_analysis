function DS = spatialBlockDownsample(XYT, downSample, coarseGrainQ)
% %Input: XYT - an array in space (x,y) and time (t) in the third dimension.
% if you want to spatially downsample a XbyT array, see
% spatialDownsampleReshaped.m
% %atm code is written so that spatial dimensions should be equal and even.
% %blockSize - single, the block size along a single dimension that will be downsampled to.

%downSample = params.down_sample;



    if ~exist('coarseGrainQ', 'var')
        coarseGrainQ = true;
    else
        coarseGrainQ = coarseGrainQ;
    end

    DS = zeros(size(XYT,1)/downSample, size(XYT,2)/downSample, size(XYT,3));
    if coarseGrainQ %average over the whole block of downSamplexdownSamplehow l
        for i = 1:downSample
            for j = 1:downSample
                DS = DS + XYT(i:downSample:end, j:downSample:end,:);
                %fr(i:downSample:end, j:downSample:end) = count;
                %count = count + 1;
            end
        end
        DS = DS/downSample^2;

    else %just pick the first element in a block of size downSamplexdownSample
        for i = 1
            for j = 1
                DS = DS + XYT(i:downSample:end, j:downSample:end,:);
                %fr(i:downSample:end, j:downSample:end) = count;
                %count = count + 1;
            end
        end

    end

      





end

