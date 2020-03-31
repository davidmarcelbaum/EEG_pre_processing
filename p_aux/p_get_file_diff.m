ls_files        = dir('/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/ICAweights/');
rej_nonformat   = find(~contains({ls_files.name}, '.set'));
ls_files(rej_nonformat) = [];

file_length(1,:) = {'Dataset', 'Original', 'New'};

for s_file = 1 : numel(ls_files)
    
    EEG = pop_loadset('filename', ls_files(s_file).name, ...
        'filepath', ls_files(s_file).folder);
    
    file_length{s_file+1,1} = ls_files(s_file).name;
    file_length{s_file+1,2} = EEG.pnts;
    
end

ls_files        = dir('/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/DataChans/');
rej_nonformat   = find(~contains({ls_files.name}, '.set'));
ls_files(rej_nonformat) = [];

for s_file = 1 : numel(ls_files)
    
    EEG = pop_loadset('filename', ls_files(s_file).name, ...
        'filepath', ls_files(s_file).folder);
    
    file_length{s_file+1,3} = EEG.pnts;
        
end

file_length{1,4} = 'Diff';
[file_length{2:end,2}]' - [file_length{2:end,3}]'