
function av_stats = segmented_avalanche_analysis(ImgF, validPixels, adjmat, network, params)

%rather than compute avalanches across the whole recording, we will do
%various segementation steps. This means we don't have to look back as
%far and saves memory
%first pass to segment periods of activity
av_stats = struct();
threshold = params.threshold;

segTimes = get_non_zero_segments(nansum(ImgF));

S = cell(1);
D = cell(1);
merged = cell(1);
roots = cell(1);
rootTimes = cell(1);
branches = cell(1);


for s = 1:length(segTimes)
    seg = (ImgF(:, segTimes{s}));

    seg(isnan(seg)) = 0;
    seg = seg > threshold;
    seg = single(seg);
 

 
  
    if sum(sum(seg)) == 0 %if activity has been thresholded out skip segment
        continue
    else
        %second pass to get periods of activity
        segTimes2 = get_non_zero_segments(nansum(seg));

        

        for s2 = 1:length(segTimes2)
            %[s, length(segTimes), s2, length(segTimes2)]
            t0 = segTimes{s}(1) + segTimes2{s2}(1);
            seg2 = seg(:, segTimes2{s2});
            if length(segTimes2{s2}) > 1
                
                
                
                [S{end+1}, D{end+1}, merged{end+1}, ~, roots{end+1}, rootTimes{end+1}, branches{end+1}] = getAvalanches(seg2, network, adjmat, validPixels, 1);
                
            else
                S{end+1} = sum(seg2);
                D{end+1} = 1;
                merged{end+1} = 0;
                roots{end+1} = find(seg2 > 0);
                rootTimes{end+1} = t0;
                branches{end+1} = roots{end};
            end
        end
    end
end


av_stats.size = {S{2:end}};
av_stats.duration = {D{2:end}};
av_stats.merged = {merged{2:end}};
av_stats.roots = {roots{2:end}};
av_stats.rootTimes = {rootTimes{2:end}};
av_stats.branches = {branches{2:end}};
av_stats.validpixels = validPixels;


end