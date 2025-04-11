

function [segmentToKeep, goodFrames] = get_segments_to_keep(json, params);%T0, recLen, recordingName, params );
%      get the frames with no excessive motion
%     some of the recordings are split up. This can cause problems with the motionIndex file.
%     the stupid way around this is to force an error which will then return the length of the motionIndex file,
%     which is then seperated

T0 = json.init.offset;
recordingName = get_raw_loc(json);

if isfield(params, 'tStep')
        if isnumeric(params.tStep)
            recLen = params.tStep;
        else
            recLen = json.init.duration;
        end
    else
        recLen = json.init.duration;
    end


if isfield(params, 'batch_blocks')
    batchblocks = params.batch_blocks;
else
    batchblocks = 1;
end

if isfield(params, 'segmentDurationThreshold')
    segmentDurationThreshold = params.segmentDurationThreshold;
else
    segmentDurationThreshold = 200;
end

tSteps = 1000000;
try 
    
motionIndex = fetchMotionErrorFile( recordingName, [256, 256, tSteps]);
catch exception
    if strcmp(exception.identifier, 'MATLAB:badsubscript')
        tSteps = exception.message;
       tSteps = strsplit(tSteps, ' ');
       tSteps = str2num(tSteps{end}(1:end-1));
       motionIndex = fetchMotionErrorFile( recordingName, [256, 256, tSteps]);
    end
end

    %find segments of recording we want to keep (ie. long with no motion
    %artifact. If no segments are found then continue to next animal
    accTime = 1:tSteps; 
    
    accTime = accTime(T0:T0+recLen-1).*motionIndex(T0:T0+recLen-1)';
    accTime = accTime(1:end - mod(recLen, batchblocks)); %batchblocks may remove a few frames from the end
    
    %now make sure we are counting from one
    accTime = accTime - T0 + 1;
    accTime(accTime < 0) = 0;

    s = segmentSeries(accTime);
    goodFrames = s(2:2:end);
    %goodFrames = [goodFrames{:}];
    badFrames = s(1:2:end);
    Lgood = cellfun(@length, goodFrames);
    Lbad = cellfun(@length, badFrames);
    segmentToKeep = find(Lgood > segmentDurationThreshold);
end