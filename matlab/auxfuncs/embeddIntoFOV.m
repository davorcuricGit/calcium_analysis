function volume = embeddIntoFOV(data, validPixels, FOVsize, varargin)
%FOVsize should be width x height

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