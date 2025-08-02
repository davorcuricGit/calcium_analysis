clear all
%% get the files

lines = readlines("dirs_to_filter.txt");

folders = [];
for n = 1:length(lines)
    d = dir(fullfile(lines{n},'**','*fChan.dat'));
    folders = [folders {d.folder}]
end
%
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
