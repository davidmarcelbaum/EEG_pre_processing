%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Best practice is to compute as many components as channels used for
% recording. ICA is more prone to introducing errors when underfitted 
% (too few componenets computed) than when overfitted.
% Artefact rejection is subjective and follows only guidelines for common
% noise artefacts such as eye blinks and vertical eye movements.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for script part-specific subfolders in preProcessing %%%%%%
if exist(folderICAWeights, 'dir') ~= 7 && stepLevel < 5
    mkdir (folderICAWeights);
    foldersCreated(end+1) = {folderICAWeights};
end

% Files will be loaded from intitial dataset folder if .set
% were chosen during fileFormat question and in subfolder
% folderRAW if initial file format was 2 (.mff)
FilesList = dir([pathName,'*.set']);

%Load one dataset into EEGLAB. This is necessary for the
%EEG.chanlocs afterwards (until line 231)
if ~exist('startPointScript', 'var') || strcmp(startPointScript,'Yes')
    msgbox('The next step will take a while depending on the size of your first dataset. The EEGLAB window will close automatically. You can close this window.')
    ALLCOM = {};
    ALLEEG = [];
    CURRENTSET = 0;
    EEG = [];
    [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
    
    EEG = pop_loadset('filename',FilesList(1).name,'filepath',pathName);
    
    EEG = eeg_checkset( EEG );
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    close all;
    
end

%Ask user to select channels for ICA
channelListICA = {EEG.chanlocs.labels}';
[selectedChannels] = listdlg('PromptString',[{'Please select the cannels you would like to include.'} {''} {''}],'ListString', channelListICA);

%This is an attempt to dynamically adapt the script to different file name types and lengths.
%conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
%    'Base name structure', 1, {FilesList(1).name}));
%conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
%    'Base name structure', 1, {FilesList(1).name}));

uiwait(msgbox('Starting script after closing this window...'));

Filenum = 0;
cyclesRun = 0;

%For every file that has been charged into the FilesList variable:
for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
    
    %Extract the base file name in order to append extensions afterwards
    fileNameComplete = char(FilesList(Filenum).name);
    fileName = fileNameComplete(1:conservedCharacters);
    
    %In order to make this clean, it saves files in a new ICAWeights directory of the mother directory
    newFileName = strcat(fileName, '_ICAWeights.set');
    
    %This avoids re-running ICA on datasets that ICA has already been run on.
    existsFile = exist ([folderICAWeights, newFileName], 'file');
    
    if existsFile ~= 2
        
        %This is important because EEGLAB after completing the task leaves some windows open.
        close all;
        
        %Initializes the variables EEG and ALLEEG that are needed later. For some reason,
        %the functions work better when EEGLAB initializes the variables itself, which is
        %why I added the last line.
        ALLCOM = {};
        ALLEEG = [];
        CURRENTSET = 0;
        EEG = [];
        [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
        
        %Function to load .set into EEGLAB
        EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
        
        %Stores daataset in first (0) slot.
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = eeg_checkset( EEG );
        
        %Look if dataset contains Trigger channel because ICA should not be run on this channel.
        %This only works if Trigger channel, if present, is located in the last row of the EEG.data variable
        %searchTrigger = strfind(strcat(EEG.chanlocs.labels), 'Trigger');
        
        %if isempty(searchTrigger)
        %    ChannelsICA = EEG.nbchan;
        %else
        %    ChannelsICA = EEG.nbchan-1;
        %end
        
        %Calculate the sum of each row in EEG.data in order to identify the channel used for reference during recording
        %(This one will always be "0" at any time point)
        %Afterwards start ICA
        %checkSums = sum(EEG.data,2)
        %[zeroPosition] = find(checkSums==0);
        %if ~isempty(zeroPosition)
        %end
        
        %Function to run ICA with specific parameters
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','off','chanind',selectedChannels);
        EEG = eeg_checkset( EEG );
        
        %Append "ICAWeights" to filename in order to not overwrite existing datasets.
        EEG = pop_editset(EEG, 'setname', newFileName);
        
        %Saving new file name to ICAWeights folder created earlier
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderICAWeights);
        EEG = eeg_checkset( EEG );
        
        cyclesRun = cyclesRun + 1;
    end
    
end
close all;