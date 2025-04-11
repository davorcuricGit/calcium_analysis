
function Av = updateAvalanche(Av, t, clusterSize)


if t > Av.endTime
Av.endTime = single(t);%Av.avtime(end);%X(2,end);
end
Av.duration = Av.endTime - Av.startTime +1;
Av.size = Av.size + clusterSize;%(X,2);%size(Av.event,2);
end