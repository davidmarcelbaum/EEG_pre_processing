% check for script part-specific subfolders in preProcessing
if exist(folderFiltRef, 'dir') ~= 7
    mkdir (folderFiltRef);
    foldersCreated(end+1) = {folderFiltRef};
end

%% Load one dataset into EEGLAB.
% This is necessary for the EEG.chanlocs afterwards
% also useful for initializing the EEGLAB variables and functions
fprintf('<!> The next step will take a while depending on the size of your first dataset.\n<!> The EEGLAB window will close automatically\n')
ALLCOM = {};
ALLEEG = [];
CURRENTSET = 0;
EEG = [];
[ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
close all;

if strcmp(fileFormat,'.set')
    
    EEG = pop_loadset('filename',dataList(dataFormat(1)).name, ...
        'filepath',pathName);
    
elseif strcmp(fileFormat,'.mff')
    
    EEG = pop_mffimport([pathName, dataList(dataFormat(1)).name], ...
        {'classid' 'code' 'description' 'label' 'mffkey_cidx' ...
        'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' ...
        'sourcedevice'});
    
elseif strcmp(fileFormat,'.cdt')
    
    EEG = loadcurry([pathName, dataList(dataFormat(1)).name], ...
        'CurryLocations', 'False');
    % Stay attentive, since this function will call eeg_checkset which
    % will complain about the fact that timepoints of recording is
    % different from data columns which is due to the fact that data is
    % not saved while checking impedance during recording
    
end


% Define the channel to be excluded during the referencing step
idx_chans2rej = []; % Find positions of channels to reject
for i = 1 : numel(chans2rej)
    idx_chans2rej(end+1) = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans2rej(i))));
end

% Reject absent channels
idx_emptychan = []; % Label of empty channels
for i = 1 : numel(chansempty)
    idx_emptychan(end+1) = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chansempty(i))));
end


%% Change channel locations if not present
questLocateChannels = [];
if isempty(EEG.chanlocs(1).X)
    
    questLocateChannels = ...
        questdlg('Do you want to locate channels?', ...
        'Locate channels', 'Yes', 'No', 'Yes');
    
    if strcmpi(questLocateChannels, 'Yes')
        
        [channelLocationsFile, channelLocationsPath] = ...
            uigetfile('*.elp', ...
            'Look for channel locations file', eeglabFolder);
        
        channelLocationsInfo = ...
            strcat(channelLocationsPath, channelLocationsFile);
        
    end
end


cyclesRun = 0;


fprintf('<!> Starting script now...\n');


%% Going through files    
FilesList = dir(strcat(pathName, '*', char(fileFormat)));

for Filenum = 1:numel(FilesList)
    
    
    %Extract the base file name in order to append extensions afterwards
    fileNameComplete = char(FilesList(Filenum).name);
    fileName = extractBefore(fileNameComplete, fileFormat);
    
    newFileName = strcat(fileName, '_FiltRef.set');
    
    
    existsFile = exist([folderFiltRef, newFileName], 'file');
    
    if existsFile ~= 2
        
        
        if strcmp(fileFormat, '.mff')
            %Function to import .mff folder into EEGLAB
            EEG = pop_mffimport([pathName, fileNameComplete], ...
                {'classid' 'code' 'description' 'label' 'mffkey_cidx' ...
                'mffkey_gidx' 'mffkeys' 'mffkeysbackup' ...
                'relativebegintime' 'sourcedevice'});
            EEG = eeg_checkset( EEG ); % This checks dataintegrity
            
            
        elseif strcmp(fileFormat, '.cdt')
            %Function to import .cdt Curry8 file into EEGLAB
            EEG = loadcurry([pathName, fileNameComplete], ...
                'CurryLocations', 'False');
            
        end
        
        
        if strcmpi(questLocateChannels, 'Yes')
            EEG = pop_chanedit(EEG, 'lookup',channelLocationsInfo);
            EEG = eeg_checkset( EEG );
        end
        
        if ~isempty(idx_emptychan)
            EEG = pop_select( EEG, 'nochannel', idx_emptychan);
            EEG = eeg_checkset( EEG );
        end
        
        
        % Check data integrity
        [EEG, lst_changes] = eeg_checkset( EEG );
        
        
        %% Filter data
        
        % Temporarily store EEG.pnts
        ori_EEG.pnts = EEG.pnts;
        
        % The filter function will throw an error if
        % EEG.pnts > size(EEG.data, 2)
        EEG.pnts = size(EEG.data,2);
        
        EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1, 'hicutoff', 45, ...
            'filtorder', 33000);
        % Filtorder = filter length - 1; filter length: how many
        % weighted data points X compose filtered data Y
        
        EEG.pnts = ori_EEG.pnts; % Muting this introduces wrong time points
        % in EEG.times
        
        % Check data integrity
        [EEG, lst_changes] = eeg_checkset( EEG );
        
        
        % Re-reference data to mean of all channels except exluded ones
        EEG = pop_reref( EEG, [], 'exclude', idx_chans2rej);
        [EEG, lst_changes] = eeg_checkset( EEG );
        
        
        EEG = pop_editset(EEG, 'setname', newFileName);
        [EEG, lst_changes] = eeg_checkset( EEG );
        
        
        EEG = pop_saveset( EEG, 'filename', newFileName, ...
            'filepath', folderFiltRef);
        
        
        cyclesRun = cyclesRun + 1;
        
        
    end
    
end
