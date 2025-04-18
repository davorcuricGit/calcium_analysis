function fillBetweenCurves(x, topCurve, botCurve, varargin)

    clr = ''; 
    falpha = 0.5;
    ealpha = 0.25;

    p = inputParser;
    addRequired(p,'x');
    addRequired(p,'topCurve');
    addRequired(p,'botCurve');
    
    addParameter(p,'color',clr);%,@ischar | @isnumeric);
    addParameter(p,'facealpha',falpha);
    addParameter(p,'edgealpha',ealpha);
    
    
    parse(p,x,botCurve, topCurve,varargin{:});

    clr = p.Results.color;
    ealpha = p.Results.edgealpha;
    falpha = p.Results.facealpha;

    
    x2 = [x, fliplr(x)];
    %x2 = [x, x];
    
    inBetween = [botCurve, fliplr(topCurve)];
    h = fill(x2, inBetween, clr);
    
    set(h, 'facealpha', falpha)
    fclr = get(h, 'facecolor');
    
    set(h, 'edgecolor', fclr)
    set(h, 'edgealpha', ealpha)

end

