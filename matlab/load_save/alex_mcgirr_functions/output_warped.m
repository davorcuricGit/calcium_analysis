function img=output_warped(ImgF,tform,dorsalMaps)
% use tform to output transformed
ImgF_warped=imwarp(ImgF,tform,'OutputView',imref2d(size(dorsalMaps.dorsalMapScaled)));

%clip into 256*256 window (HARD CODED)
img=ImgF_warped;
yind=(151-127):(152+127);
xind=15:(15+255);
img=img(xind,yind,:);

end