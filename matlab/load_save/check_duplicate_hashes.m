
  

function [flag, hash_dupe_list] = check_duplicate_hashes(Ttot);
%check for duplicates
hash_dupe_list = {};
hashes = Ttot(:,'subject_id').subject_id;
uqhashes = uniquecell(hashes);
if length(uqhashes) ~= length(hashes)
    %try to find a duplicate
    for n = 1:length(uqhashes)
        testhash = uqhashes{n};
        if sum(strcmp(hashes,testhash)) > 1
            hash_dupe_list{end+1} = testhash;
        end
    end
    flag = true;
else
    flag = false;
end

end