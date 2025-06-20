clear all

%%%% put path to the calcium analysis directory here
calcium_dir = '/home/dcuric/Documents/calciumAnalysis/';
%%%%

%get which computer we are currently on
computer = char(get_computer_alias([calcium_dir '/computers.csv']));

av_json = fullfile( calcium_dir, 'project_jsons', 'sourcesink_networks.json');
av_json = jsondecode(fileread(av_json));

%most of the time the number of projects will be 1.
project_lists = readtable([calcium_dir 'project_lists/', ...
    computer '_project_lists.txt'],'Delimiter', ',',  'ReadVariableNames', false);

%loop over projects
for p = 1:height(project_lists)
    project = project_lists(p,:).Var1{1};
    project = jsondecode(fileread(project));

    %get paths and files
    init_flag = init_analysis(project);

    subject_jsons = dir([project.project_root '/' project.project_name, '/' project.structure.metadata '/**/*.json']);

    av_json.needs = 'subnet_time_series';
    av_json.type = 'avalanches';

    %loop over subjects
    for i = 2%:length(subject_jsons)

        row = subject_jsons(i);
        json = fileread([row.folder '/' row.name]);
        json = jsondecode(json);

        %load calcium recording
        %project.raw_parameters.tSteps = 5000;
        [ImgF, segs, goodFrames, badFrames, json,validPixels, ME] = load_calcium(json,project);

        av_json.needs = 'subnet_time_series';
        av_json.type = 'allen_subnets_timeseries';
        dmeta = json.(av_json.needs).(av_json.type);
        [v,ME] = get_needed_derivative(dmeta, json, project);

    stop
       clear ImgF
    end

end
%
%%
clf
nrows = 2;
ncols = 2;

px = 1;
sz = [json.init.height, json.init.width]; %width x height of original recording

%plot the full time series of one pixel
subplot(nrows, ncols, 1)
plot(ImgF(px,:))
xlim([1, json.init.duration])

%plot a good segement from the recorindg
subplot(nrows, ncols, 3)
k = 2;
plot(goodFrames{k}, ImgF(px,goodFrames{k}))
xlim([goodFrames{k}(1), goodFrames{k}(end)])

%plot the pixels across the corrtical surface
subplot(nrows, ncols, 2)
FOV = embeddIntoFOV(validPixels, validPixels, sz);
imagesc(FOV)

%plot the average of the recoridng
subplot(nrows, ncols, 4)
avgF = nanmean(ImgF')';
FOV = embeddIntoFOV(avgF, validPixels, sz);
imagesc(FOV)

%% downsample the recording

[ImgF_ds, validPixels_ds, sz_ds] = spatial_downsample_reshaped(ImgF, project.raw_parameters.down_sample, project.ImgF_processing);

%plot the full time series of one pixel
subplot(nrows, ncols, 1)
plot(ImgF_ds(px,:))
xlim([1, json.init.duration])

%plot a good segement from the recorindg
subplot(nrows, ncols, 3)
k = 2;
plot(goodFrames{k}, ImgF_ds(px,goodFrames{k}))
xlim([goodFrames{k}(1), goodFrames{k}(end)])

%plot the pixels across the corrtical surface
subplot(nrows, ncols, 2)
FOV = embeddIntoFOV(validPixels_ds, validPixels_ds, sz_ds);
imagesc(FOV)

%plot the average of the recoridng
subplot(nrows, ncols, 4)
avgF = nanmean(ImgF_ds(:, goodFrames{1})')';
FOV = embeddIntoFOV(avgF, validPixels_ds, sz_ds);
imagesc(FOV)
%% embedd downsampled recording onto FOV
clf
T = 25;
nrows = 5;
ncols = 5;
FOV = embeddIntoFOV(ImgF_ds, validPixels_ds, sz_ds);
for i = 1:T
    subplot(nrows, ncols, i)
    imagesc(FOV(:,:,goodFrames{1}(i)))
    title(['Frame = ' num2str(goodFrames{1}(i))])
    xticks([])
    yticks([])
    colorbar()
    clim([-1,1])
end