d = dir(fullfile('/scratch2/DavorCuric/AlexMcGirr/Acute Drug 2021/','**','*fChan.dat'));
fChanfolders1 = {d.folder};
d = dir(fullfile('/scratch2/DavorCuric/AlexMcGirr/Acute Drug 2021/','**','*Spontaneous_50Hz_filt01-15_float32*'));
Spontfolders1 = {d.folder};

d = dir(fullfile('/scratch2/DavorCuric/AlexMcGirr/Microbeads/','**','*fChan.dat'));
fChanfolders2 = {d.folder};
d = dir(fullfile('/scratch2/DavorCuric/AlexMcGirr/Microbeads/','**','*Spontaneous_50Hz_filt01-15_float32*'));
Spontfolders2 = {d.folder};



fChanfolders = [fChanfolders1 fChanfolders2];

for i = 1:length(fChanfolders)
    path = [fChanfolders{i} '/fChan.dat'];
    
    delete(path)



end
