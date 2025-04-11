
function x = removeEmptyCells(x)

    x = x(~cellfun('isempty',x));
    
end