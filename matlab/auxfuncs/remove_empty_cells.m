
function [x,non_empty_idx] = remove_empty_cells(x)

    non_empty_idx = find(cellfun('isempty',x) == 0);
    x = x(non_empty_idx);
    
end