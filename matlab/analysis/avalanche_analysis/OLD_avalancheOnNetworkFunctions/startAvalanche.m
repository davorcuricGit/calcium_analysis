
      function Av = startAvalanche(avCount, cluster, t)
            
      
if size(cluster,1)~=1; cluster = cluster'; end
      
            Av = avalanche;
            Av.label = avCount;
            Av.size = length(cluster);
            Av.startTime = t;
            Av.endTime = t; %this will be incremented later
            %Av.event = [Av.event [cluster; t*ones(size(cluster))]];
            Av.roots = single(cluster);
            
            Av.rootTime = single(t*ones(size(cluster)));
            
            Av.duration = 1;
            Av.branches = single(cluster)';%[];%[];
            
            %Av.avtime = [t];
        end
 