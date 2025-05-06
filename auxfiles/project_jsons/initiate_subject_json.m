clear all
run('/home/dcuric/Documents/calciumAnalysis/matlab_codes/init_analysis.m')


%INPUT HERE
fileName = ['config_microbead_project.json']; % filename in JSON extension

json_dir = '/home/dcuric/Documents/calciumAnalysis/analysis/';
str = fileread([json_dir '/' fileName]); % dedicated for reading files as text
data = jsondecode(str); % Using the jsondecode function to parse JSON from string
computer = data.computer;
project_root = data.project_root;
T = readtable([json_dir 'allRecordings_' computer '.csv']);

%for the hash functions
addpath('/home/dcuric/Documents/calciumAnalysis/matlab_codes/load_save/')
addpath('/home/dcuric/Documents/calciumAnalysis/matlab_codes/aux/')
addpath(genpath('/home/dcuric/Documents/calciumAnalysis/matlab_codes/filtercodes/'))

flag = check_duplicate_hashes(T);

%%

for n = 1:height(T)
    
    dir_name = strrep(strrep(T.paths{n}, 'raw_data/', ''), project_root, '');
    S = struct();
    S.raw_path = dir_name;
    S.name = strrep(T.names{n}, '.raw', '');
    S.condition = T.condition{n};
    S.mouse = T.mouse(n);
    S.duration = T.durations(n);
    S.height = 256;
    S.width = 256;
    S.offset = T.frameoffset(n);
    S.dataset = T.dataset{n};
    S.recid = T.rec_id(n);
    S.uniqueid = T.subject_id{n};
    S.timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    S.project_root = project_root;
    S.machine_p = T.machine_p{n};

    save_dir = fullfile(project_root,'derivatives', 'metadata', dir_name);
    if ~isfolder(save_dir)
        mkdir(save_dir)
    end
    save_name = S.uniqueid;
    
    metadata = struct();
    metadata.('init') = S;
    
    processing = struct();
    if contains(S.name, 'filt')
        processing.filtered = 'True';
        processing.band = T.filter{n};
    else
        processing.filtered = 'False';
    end

    transform_file = [project_root '/raw_data/'  S.raw_path '/transform.mat' ];
    if isfile(transform_file)
        processing.transform = [S.raw_path '/transform.mat' ];
    else
        processing.transform = 'missing';
    end

    frameerror_file = [project_root '/raw_data/'  S.raw_path '/frame_error.mat' ];
    if isfile(frameerror_file)
        processing.frame_error = [S.raw_path '/frame_error.mat' ];
    else
        processing.frame_error = 'missing';
    end
    metadata.('processing') = processing;



    json_text = jsonencode(metadata);
    fid = fopen(fullfile(save_dir, [save_name, '.json']), 'w');
    fwrite(fid, json_text, 'char');
    fclose(fid);

    
end

subject_jsons = dir([project_root '/derivatives/metadata*/**/*.json']);