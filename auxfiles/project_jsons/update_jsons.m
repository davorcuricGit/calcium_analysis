clear all

project_name = 'Microbeads';

subject_jsons = dir([project_name '/metadata/**/*.json']);


for i = 1:length(subject_jsons)

        row = subject_jsons(i);
        json = fileread([row.folder '/' row.name]);
        json = jsondecode(json);
        json.init.raw_path = strrep(json.init.raw_path, project_name, '');
        json.init.project_root = ['/scratch4/calcium_data/projects/' project_name '/'];
        
        json_text = jsonencode(json);
        fid = fopen([row.folder '/' row.name], 'w');
        fwrite(fid, json_text, 'char');
        fclose(fid);

        
end

