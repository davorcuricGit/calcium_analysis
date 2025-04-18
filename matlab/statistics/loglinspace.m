

function loglin = loglinspace(xmin, xmax, npnts)
    loglin = 10.^(linspace(log10(xmin), log10(xmax), npnts));
end
