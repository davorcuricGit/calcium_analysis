
function spikeTimes =  getSpikeTimings(dd, th);

dd(dd < th) = 0;
dd(dd ~= 0) = 1;

for t = 1:size(dd,1);
    spikeTimes{t} = find(dd(t,:) == 1);
end
end


