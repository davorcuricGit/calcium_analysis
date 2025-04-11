function DS = spatialBlockDownsample(XYT, downSample, coarseGrainQ)
% %Input: XYT - an array in space (x,y) and time (t) in the third dimension.
% %atm code is written so that spatial dimensions should be equal and even.
% %blockSize - single, the block size along a single dimension that will be downsampled to.

if ~exist('coarseGrainQ','var')
    coarseGrainQ = true;
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


% 
% 
% function [dsF, frame] = spatialBlockDownsampleTEST(XYT, blockSize); 
% 
% %Input: XYT - an array in space (x,y) and time (t) in the third dimension.
% %atm code is written so that spatial dimensions should be equal and even.
% %blockSize - single, the block size along a single dimension that will be downsampled to.
% 
% %Output: dsF - the downsampled data 
% 
% L = size(XYT, 1);
% 
% %blockSize = 2; %block size in one dimension
% 
% clear dsF
% 
% for i = 1:floor(L/blockSize);
%     for j = 1:floor(L/blockSize);
%     
%     blk = XYT(blockSize*(i-1)+1:blockSize*i+blockSize-blockSize, blockSize*(j-1)+1:blockSize*j+blockSize-blockSize,:);
%     
%     dsF(i,j,:) = squeeze(mean(mean(blk)));
%     %dsF(i,j,:) = sum(reshape(blk, 1, []));
%     end
% end
% clear blk
% end