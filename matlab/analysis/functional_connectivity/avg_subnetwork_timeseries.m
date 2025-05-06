function [v, nanidx] = avg_subnetwork_timeseries(ImgF, subnetworks, params);
    %for each subnetwork get the avg time series
    %ImgF is NxTime
    %subnetworks is cell 1xM cell with each cell containing the pixels
    %belonging to the subnetwork
    %optionally, randomly sample within the field of view.

     v = zeros(length(subnetworks), size(ImgF, 2));

     for i = 1:length(subnetworks);
        px = subnetworks{i};

        if isfield(params, 'random_sample')
        if params.random_sample;
            px = datasample(px, floor(length(px)/2), 'Replace', false);
        end
        end

        
        v(i,:) = nanzscore(nanmean(ImgF(px,:)));
        
    end
    
    nanidx = nansum(v')';
    nanidx = find(nanidx == 0);

end