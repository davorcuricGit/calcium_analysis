clear all
d = dir('**/*Spontaneous_50Hz*/*.raw');
%
names = {d.name};
paths = {d.folder};

%for the hash function
addpath('/home/dcuric/Documents/calciumAnalysis/')

%%
project_dir = '/scratch4/calcium_data/';
clear durations condition mouse sex t0 outlier recid height width computer loc filter machine_p
for n = 1:length(names)

    t0{n} = 1;
    outlier(n) = 0;
    recid(n) = n;

    

    durations{n} = str2num(names{n}(end-8:end-4));
    
    pathname = paths{n};
    
    loc{n} = strrep(strrep(pathname, [project_dir ], ''), 'data_raw/','');

    idx = strfind(paths{n}, '_Spontaneous_');
    mouse{n} = str2num(paths{n}(idx-4:idx-2));
    sex{n} = paths{n}(idx-1);
    dataset{n} = 'accute_stress';
    cohortnum = strfind(paths{n}, ' Cohort ');
    cohortnum = paths{n}(cohortnum+8);
    

    condition{n} = 'WARNING';
    %pathname
    if contains(pathname, '/Novel Environment Control/')
        condition{n} = 'Nov.Env.Ctrl';
    elseif contains(pathname, '/Homecage Control/') | contains(pathname, '/Homecage/') | contains(pathname, '/HomecageControl/')
        condition{n} = 'Homecage Ctrl';
     elseif contains(pathname, '/Acute Chronic Stress/')
        condition{n} = 'Chronic';    
     elseif contains(pathname, '/Acute Chronic Stress Post 24hrs Ketamine/')
        condition{n} = 'ChronicKet';       
    elseif contains(pathname, '/Acute Stress/')
        condition{n} = 'Acute';
   
    else
        pathname
    end

    tagadd = 'WARNING';
    if contains(pathname, 'Baseline')
            tagadd = '/Baseline';
%       
    elseif contains(pathname, 'Post 1 Hour') | contains(pathname, 'Post 1Hr')
            tagadd = '/Post1Hr';
        
    elseif contains(pathname, 'Post 24 Hours') | contains(pathname, 'Post 24Hrs')
        tagadd = '/Post24Hr';    
        
    elseif contains(pathname, 'Post Novel Environment')
        tagadd = '/PostNov.Env.';    
        
            elseif contains(pathname, 'Post Homecage')
                tagadd = '/PostHomecage';
           
            elseif contains(pathname, 'Post Shock')
                tagadd = '/PostShock';
            elseif contains(pathname, '24 Hours')
                tagadd = '/24Hours';    
           
    else
        pathname
    end

    condition{n} = [condition{n} tagadd];
    condition{n} = [condition{n} '/cohort' num2str(cohortnum)];
    condition{n} = strrep(condition{n}, '/', '_');

    h{n} = 256;
    w{n} = 256;
    computer{n} = 'neumann';
    machine_p{n} = 'float32';
    filter{n} ='01-15';
end

T = table(names', loc', durations', condition', mouse', sex', dataset', outlier', t0', recid', h', w', computer', machine_p', filter', 'variableNames', {'names', 'paths', 'durations', 'condition', 'mouse', 'sex', 'dataset', 'outlier', 'frameoffset', 'rec_id', 'height', 'width', 'computer', 'machine_p', 'filter'});
%save('recordings_stress.mat', 'T')
for i = 1:height(T)
    str = [T(i,:).names T(i,:).mouse T(i,:).condition T(i,:).dataset T(i,:).sex T(i,:).filter];
    hash{i} = [DataHash(str)];
    hash{i} = ['id_' hash{i}(1:2:end)];
end

T.subject_id = hash';

%check for duplicates
hashes = T(:,'subject_id').subject_id;
uqhashes = uniquecell(hashes);
if length(uqhashes) ~= length(hashes)
    'Duplicates!'
    %try to find a duplicate
    for n = 1:length(uqhashes)
        testhash = uqhashes{n};
        if sum(strcmp(hashes,testhash)) > 1
            testhash
        end
    end

else
    'Its gucci'
    save(['recordings_'  dataset{1}  '.mat'], 'T')
end



%clear d
%d.name = names

%save('recordings.mat', 'd');
