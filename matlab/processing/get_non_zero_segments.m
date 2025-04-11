

function segTimes = get_non_zero_segments(trace);
    trace(1) = 0;
    trace(end) = 0;
    [~, segTimes] = segmentSeries(trace);
    segTimes = {segTimes{2:2:end}};
    
end