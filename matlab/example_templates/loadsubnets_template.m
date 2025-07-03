clear all
computer = char(get_computer_alias('/home/dcuric/Documents/calciumAnalysis/computers.csv'));

av_json = '/home/dcuric/Documents/calciumAnalysis/project_jsons/sourcesink_networks.json';
av_json = jsondecode(fileread(av_json));


project_lists = readtable(['/home/dcuric/Documents/calciumAnalysis/project_lists/', ...
    computer '_project_lists.txt'],'Delimiter', ',',  'ReadVariableNames', false);


%loop over projects
for p = 1:height(project_lists)
    project = project_lists(p,:).Var1{1};
    project = jsondecode(fileread(project));

    %get paths and files
    [init_flag, loaded] = init_analysis_v2(project);

    subject_jsons = dir([project.project_root '/' project.project_name, '/' project.structure.metadata '/**/*.json']);

    %loop over subjects
    for i = 1:length(subject_jsons)

        row = subject_jsons(i);
        json = fileread([row.folder '/' row.name]);
        json = jsondecode(json);

        av_json.dorsalMaps = loaded.dorsalMaps;

        %get the per-subject subnetworks
        [subnetwork, subnetworksFOV] = get_allen_subnetworks(json, av_json.dorsalMaps, ...
            downsample = 1, ...
            globalmask = project.ImgF_processing.mask_name);
        
    end
end
