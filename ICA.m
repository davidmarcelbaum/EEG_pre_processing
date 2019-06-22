%Since the path to EEGLAB differs between systems, locate EEGLAB and its functions.
locateEeglab = which('eeglab.m');
eeglabFolder = erase(locateEeglab, 'eeglab.m');

%Determine which system Matlab runs on in order to avoid problems with forward/backward slashs in Windows vs Unix-like.
strSystem = computer;

%Point Matlab to the EEGLAB functions in order to be be able to call them later by adding the paths with Windows-specific "\".
strVerify = strfind(strSystem,'PCWIN');

if isempty(locateEeglab)
    functionsEEGLAB = uigetdir(matlabroot,'Point to the folder >>functions<< of EEGLAB');

    if isempty(strVerify)
        addpath(strcat(functionsEEGLAB, '/', 'adminfunc', '/'));
        addpath(strcat(functionsEEGLAB, '/', 'popfunc', '/'));
    else
        addpath(strcat(functionsEEGLAB, '\', 'adminfunc', '\'));
        addpath(strcat(functionsEEGLAB, '\', 'popfunc','\'));
    end
else
    if isempty(strVerify)
        addpath(strcat(eeglabFolder, 'functions/popfunc/'));
        addpath(strcat(eeglabFolder, 'functions/adminfunc/'));
    else
        addpath(strcat(eeglabFolder, 'functions\popfunc\'));
        addpath(strcat(eeglabFolder, 'functions\adminfunc\'));
    end
end

%Give here the source folder of the .set files to be run ICA with
[FilesList, pathName, filterIndex] = uigetfile('*.set',...
   'Select one or more .set files.', ...
   'MultiSelect', 'on');

%if >1 files selected FilesList is a cell array, if 1 file only, then FilesList is a char --> transform to cell array
if ischar(FilesList)
    FilesList = {FilesList};
end

%Creates ICAWeights folder if does not exist. This is essential for saving
%the datasets later
existsICAWeights = exist ([pathName, 'ICAWeights'], 'dir');

if existsICAWeights ~= 7
    mkdir (pathName, 'ICAWeights');
end

%This is an attempt to dynamically adapt the script to different file name types and lengths.
conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
    'Base name structure', 1, FilesList(1,1)));

%For every file that has been charged into the FilesList variable:
for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements

    %Extract the base file name in order to append extensions afterwards
    fileNameComplete = char(FilesList(Filenum));
    fileName = fileNameComplete(1:conservedCharacters);

    %In order to make this clean, it saves files in a new ICAWeights directory of the mother directory
    newFileName = strcat(fileName, '_ICAWeights.set');
    
    %Again Windows-specific
    if isempty(strVerify)
        newFilePath = strcat(pathName, 'ICAWeights/');
    else
        newFilePath = strcat(pathName, 'ICAWeights\');
    end

    %This avoids re-running ICA on datasets that ICA has already been run on.
    existsFile = exist ([newFilePath, newFileName], 'file');

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
        searchTrigger = strfind(strcat(EEG.chanlocs.labels), 'Trigger');

        if isempty(searchTrigger)
           ChannelsICA = EEG.nbchan;
        else
           ChannelsICA = EEG.nbchan-1;
        end

        %Function to run ICA with specific parameters
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','off','chanind',1:ChannelsICA);
        EEG = eeg_checkset( EEG );

        %Append "ICAWeights" to filename in order to not overwrite existing datasets.
        EEG = pop_editset(EEG, 'setname', newFileName);
        EEG = eeg_checkset( EEG );

        %Saving new file name to ICAWeights folder created earlier
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
        EEG = eeg_checkset( EEG );

        %Purge dataset from memory in order to avoid unnecessary filling of system memory.
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = pop_delset( EEG, [1] );
    end

end

%Display end message
if Filenum == numel(FilesList)
    close all;
    displayedMessage = msgbox('Operation Completed');
end
