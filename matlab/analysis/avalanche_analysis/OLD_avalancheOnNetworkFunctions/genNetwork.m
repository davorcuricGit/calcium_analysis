


function [network, degDist] = genNetwork(rhob, th)

rhob(abs(rhob) < th) = 0;
rhob(abs(rhob) ~= 0) = 1;
%rhob = rhob - eye(size(rhob));



for n = 1:size(rhob,1)
    network{n} = [find(rhob(:,n) == 1)', n];
end

degDist = cellfun(@length, network);
end