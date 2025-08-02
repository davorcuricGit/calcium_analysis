function volume = embeddIntoFOV(data, validPixels, FOVsize, varargin)
%FOVsize should be width x height
%transform data from N x T into XxYxY using the validPixels from a mask

useParfor = false;
method = 'bilinear';

p = inputParser;
addRequired(p,'data');
addRequired(p,'validPixels');
addRequired(p,'FOVsize');

addParameter(p,'useParfor',useParfor, @islogical);

parse(p,data,validPixels, FOVsize,varargin{:});




volume = zeros(prod(FOVsize), size(data,2));
volume(validPixels,:) = data;

volume = reshape(volume, FOVsize(1), FOVsize(2), size(data,2));


end