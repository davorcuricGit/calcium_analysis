% revised 10/13/20 DA
% should be cross compatible with previous F_ReadRAW
% 
% Folder must contain a 'transform.mat' file for warping
% Folder must contain a 'frame_error.mat' file for error removal

% warp: 1 to output warped image stack
% rm_error: 1 to remove movement error frames

function index = fetchMotionErrorFile(filename,Sxyz)

%Sxyz
% if nargin < 2||Sxyz==0 
% Sxyz=filename;
% Sxyz(Sxyz<'0'|Sxyz>'9')=' ';
% Sxyz=str2num(Sxyz);
% Sxyz=Sxyz(end-2:end); %last three numbers need to be x,y,t
% end  
% if nargin < 3||Ftype==0; Ftype = 'float32'; end  
% if nargin < 4;warp=0;end
% if nargin < 5;rm_error=0;end
%filename

[pathname,~]=fileparts(filename);

load([pathname '/frame_error.mat'],'error');
error = error(1:Sxyz(3));
index=remove_errors(error);
%ImgF=ImgF(:,:,index);

% 
% disp(['Read file finised in ' num2str(round(toc)) 's: ' filename]);
% end
% 
% %%
% %warp
% function img=output_warped(ImgF,tform,dorsalMaps)
% % use tform to output transformed
% ImgF_warped=imwarp(ImgF,tform,'OutputView',imref2d(size(dorsalMaps.dorsalMapScaled)));
% 
% %scale down and clip
% img=imresize(ImgF_warped,.5);
% img(291:end,:,:)=[];
% img(:,[1,292,293],:)=[];
% end
% 
% %remove errors
function [index]=remove_errors(error)

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

end
