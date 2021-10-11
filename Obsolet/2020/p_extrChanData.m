%% Prerequisities
if contains(computer,'PCWIN') == 1
    filesep = '\';
else
    filesep = '/';
end

% Build save path for result saving at end
if ~exist(strcat(cd, filesep, 'DataChan'),'dir')
    mkdir(strcat(cd, filesep, 'DataChan'))
end
savePath = strcat(cd, filesep, 'DataChan', filesep);

%% Set up user land
pathName = strcat(uigetdir(cd,'Choose the folder that contains the datasets'),filesep);

FilesList = dir([pathName,'*.set']);

looped = 0;

%% Magical unicorn loop
for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements

    %Initializes the variables EEG and ALLEEG that are needed later. For some reason,
    %the functions work better when EEGLAB initializes the variables itself, which is
    %why I added the last line.
    ALLCOM = {};
    ALLEEG = [];
    CURRENTSET = 0;
    EEG = [];
    [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
    
    %Function to load .set into EEGLAB
    EEG = pop_loadset('filename',FilesList(Filenum).name,'filepath',pathName);
    
    %Stores daataset in first (0) slot.
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    
    for i = 1:size(EEG.chanlocs,2)
        Channel.Labels{i,1} = EEG.chanlocs(i).labels;
    end
    
    Channel.Data = EEG.data; % Contains data points
    Channel.Trials = EEG.trials; % Number of trials
    Channel.Srate = EEG.srate; % Sample rate
    Channel.TrialStart = EEG.xmin; % seconds before trigger
    Channel.TrialEnd = EEG.xmax; % seconds after trigger
    Channel.Times = EEG.times; % time points of whole set
    Channel.Pnts = EEG.pnts;
    Channel.Filename = FilesList(Filenum).name; % file name
    Channel.Origin = strcat(EEG.filepath, FilesList(Filenum).name); % where...
    % do the channels have been extracted from
    
    % Build name of file to save
    saveName = insertAfter(FilesList(Filenum).name,'sleep_','ChanDat_');
    saveName = replace(saveName,'On.set','.mat');
    
    save(strcat(savePath, saveName), 'Channel');
    
    clear EEG saveName Channel
    
    looped = looped + 1;
end

close all

if numel(FilesList) == looped
   fprintf('Done. Computed %d datasets.', looped) 
end