
function checkifDirExists(dir)
    if ~exist(dir, 'dir');
        ['directory does not exist, creating ...' dir] 
        mkdir(dir);
    end
    
end
