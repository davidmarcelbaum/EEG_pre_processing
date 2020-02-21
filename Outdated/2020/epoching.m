%Do not delete the transpose at the end of the function.
epochDimensions = str2double(inputdlg({'Seconds before trigger?','Seconds after trigger?'},...
    'Define epoch size', [1 50], {'-3';'7'})');
if epochDimensions(1) > 0
    epochDimensions(1) = -epochDimensions(1);
end
if epochDimensions(2) < 0
    epochDimensions(2) = -epochDimensions(2);
end

% check for script part-specific subfolders in preProcessing %%%%%%
if exist(folderEpochs, 'dir') ~= 7 && stepLevel < 7
    mkdir (folderEpochs);
    foldersCreated(end+1) = {folderEpochs};
end

% Files will be loaded from intitial dataset folder if .set
% were chosen during fileFormat question and in subfolder
% folderRAW if initial file format was 2 (.mff)
FilesList = dir([pathName,'*.set']);

%This is an attempt to dynamically adapt the script to different file name types and lengths.
%conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
%    'Base name structure', 1, FilesList(1,1)));
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
    newFileName = strcat(fileName, '_Epochs.set');
    
    %This avoids re-running ICA on datasets that ICA has already been run on.
    existsFile = exist ([folderEpochs, newFileName], 'file');
    
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
        
        %This will extract epochs from ALL triggers ("{ }"). This needs to
        %be changed in order to adapt
        EEG = pop_epoch( EEG, {  }, epochDimensions, 'newname', newFileName, 'epochinfo', 'yes');
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderEpochs);
        EEG = eeg_checkset( EEG );
        
        cyclesRun = cyclesRun + 1;
    end
end
close all;