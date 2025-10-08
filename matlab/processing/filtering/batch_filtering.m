clear all
%%

% Specify the main folder you want to add
mainFolder = '/home/dcuric/Documents/calciumAnalysis/codes/matlab'; % Replace with your desired folder path

% Generate a string containing the paths of the main folder and all its subfolders
pathString = genpath(mainFolder);

% Add these paths to the MATLAB search path
addpath(pathString);

%% get the files

lines = readlines("/home/dcuric/Documents/calciumAnalysis/codes/matlab/processing/filtering/dirs_to_filter.txt");

folders = [];
for n = 1:length(lines)
    d = dir(fullfile(lines{n},'**','*fChan.dat'));
    folders = [folders {d.folder}]
end

<<<<<<< HEAD
%
=======
>>>>>>> parent of 0f83d76 (some comment updates, updates to get_avalanches to accomodate variable types)
band = [0.1 15];
%
for i = 1:length(folders)
    filedir = folders{i};
    filedir
    
    datflou = load([filedir '/Data_Fluo.mat']);
    fStep = datflou.datLength;
    freq = datflou.Freq;
    

    [ImgF,Fs] = F_ReadDAT(filedir, fStep);

    F0 = mean(ImgF, 3);
    ImgF=(ImgF-F0)./F0*100;
    ImgF = F_Filt(ImgF, band, Fs);

    savename = [filedir '/Spontaneous_' num2str(freq) 'Hz_filt' ...
        strrep(num2str(band(1)), '.', '') '-' strrep(num2str(band(2)), '.', '')
        ];

    F_SaveRAW(ImgF, savename)
    clear ImgF
    delete([filedir '/fChan.dat'])

end
