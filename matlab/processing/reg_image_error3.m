% function for brain image registration
% input: image stack img(Sx,Sy,Sz)
% outputs:
% error: traditional mse error trace
% ind_mse: logical index of outlier frames
% ind_reg: logical index of outlier frames with high translation values
% trans: translation values for outlier frames
% pd: probability distribution of non-outlier frames


% this also generates a time-series graph and a histogram graph


%	VERSION 3: July 29/2025 Donovan Ashby
% corrects for high amplitude calcium events that are falsly
%	labelled as motion in previous versions
% takes the set of potential frames (use MSE) and calculates the
% rigid translation required to align to the local average frame
% removes low translation frames from the set of motion frames
% using a 95% threshold


% SLOW: frame alignment is slow. For a 10% initial error frame rate and a
% 30000 frame recording (3000 error frames), this will take ~10 min


function[error,ind_mse,ind_reg,trans,pd]=reg_image_error3(img)


[Sx,Sy,Sz]=size(img);


% moving average frame. 1500 frames is 30 sec at 50Hz
F0=movmean(img,1500,3);




% for all frames, mse from the standard deviation filtered images
disp('calculating MSE on all frames...')
error=zeros(Sz,1);
for n=1:Sz
	f=stdfilt(F0(:,:,n));
	g=stdfilt(img(:,:,n));
	error(n)=immse(single(zscore(f)>3),single(zscore(g)>3));
end


% detect outliers, 3 SD above average
thresh=3;
ind=isoutlier(error,'ThresholdFactor',thresh);
ol=find(ind);
nol=find(~ind);


%% set up image registration for outliers
[opt1, metric] = imregconfig('monomodal');
trans=zeros(2,length(ol));
% all outliers
disp(['calculating rigid translation on ' int2str(length(ol)) '/' int2str(Sz) ' frames'])
for n=1:length(ol)
	f=stdfilt(F0(:,:,ol(n)));
	g=stdfilt(img(:,:,ol(n)));
	T = imregtform(f,g,'translation',opt1,metric); %SLOW
	trans(:,n)=T.Translation;
	if mod(n,10)==0
		disp([int2str(n) '/' int2str(length(ol))])
	end
end


%% 100 sample of non-outliers
disp('generating null distribution...')
samp=randi(length(nol),100,1);
trans_nol=zeros(2,length(samp));
for n=1:length(samp)
	f=stdfilt(F0(:,:,samp(n)));
	g=stdfilt(img(:,:,samp(n)));
	T = imregtform(f,g,'translation',opt1,metric); %SLOW
	trans_nol(:,n)=T.Translation;
end


% fit a gamma distribution to the non-outlier sample to get a threshold
% non-outliers should not exceed 1 pixel motion or something is very wrong
% threshold is 95% hard coded
pd=fitdist(vecnorm(trans_nol)','Gamma');

rng=.01:.01:1000;
cdf(pd,rng);
th=rng(find(cdf(pd,rng)>.95,1));


%% generate a logical index of mse motion and reg motion
ind_mse(nol)=false;
ind_mse(ol)=true;


ind_reg=ind_mse;

size(trans)
size(vecnorm(trans))


ind_reg(ol(vecnorm(trans)<th))=false;


% plot the timeseries
figure(1);clf
plot(rescale(error));hold on
plot(ind_mse*-1)
plot(ind_reg)
scatter(ol,rescale(vecnorm(trans)))


% plot the histogram
figure(2);clf
histogram(vecnorm(trans),100,Normalization='probability');hold on
histogram(vecnorm(trans_nol),100,Normalization='probability')

end
