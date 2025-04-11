
function [state, active] = getNewState(p, validPixels)
state = rand(size(validPixels));
state(state < p) = 0;
state(state ~= 0) = 1;
active = find(state == 1);
end
