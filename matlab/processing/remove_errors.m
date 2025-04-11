%remove errors
function index=remove_errors(error)

ol=isoutlier(error);
ol(1:5)=0; %ensure first value is not an outlier
ol(end)=0; %ensure last value is not an outlier
cross=diff(ol);

x1=find(cross==1); %start of outlier
x2=find(cross==-1); %end of outlier
x1=x1-5; %5 frame buffer
x2=x2+5; %5 frame buffer

%shift to find stable segments
x2(2:end+1)=x2;
x2(1)=1;
%add end
x1(end+1)=length(ol);

dur=x1-x2;
ii=find(dur>30); %choose only segments longer than 1 sec 
ind=[];
for n=1:length(ii)
ind=cat(2,ind,x2(ii(n)):x1(ii(n)));
end

index=false(length(ol),1);
index(ind)=1;
end