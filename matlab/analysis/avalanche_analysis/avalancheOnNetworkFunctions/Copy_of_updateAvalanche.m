
function Av = updateAvalanche_OLD(Av, t, cluster)



if size(cluster,1)~=1; cluster = cluster'; end
% 
% cluster
% [cluster; t*ones(size(cluster))]
% Av.event

%Av.event = sortrows(unique(Av.event', 'rows'),2)';
X = [cluster; t*ones(size(cluster))];
X = single(unique(X','rows')');
%[t size(Av.event) size(X)]

%Z = zeros(2, size(Av.event,2) + size(X,2));
%Z(1:2, 1:size(Av.event,2)) = Av.event;
%Z(1:2, size(Av.event,2)+1:end) = X;
Av.event = [Av.event X];

%Av.event = Z;
%Av.event = unique(Av.event', 'rows')';


%Av.endTime = max(Av.event(2,:));
%Av.endTime = Av.event(2,end);
Av.endTime = Av.event(2,end);
Av.duration = Av.endTime - Av.startTime +1;
Av.size = size(Av.event,2);

end