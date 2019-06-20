%Search for EEGLAB functions folder
locateEeglab = which('eeglab.m');
eeglabFolder = erase(locateEeglab, "eeglab.m");

%Determine which system Matlab runs on
strSystem = computer;

%System-specific appendix to point Matlab to the functions used in this script.
strVerify = strfind(strSystem,'PCWIN');

if isempty(locateEeglab)
    %Point to functions used in this sript
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

%Give here the source folder of the .mff files to be run Filter on
pathName = uigetdir();
if isempty(strVerify)
    pathName = strcat(pathName, '/');
else
    pathName = strcat(pathName, '\');
end
FilesList = dir([pathName,'*.mff']);

%Creates preProcessing folder if does not exist. This is essential for saving
%the datasets later
existsPreProcessing = exist ([pathName, 'preProcessing'], 'dir');

if existsPreProcessing ~= 7
    mkdir (pathName, 'preProcessing');
end

conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
    'Base name structure', 1, FilesList(1)));

for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements

    %Function to get the file name
    fileNameComplete = FilesList(Filenum).name;
    fileName = fileNameComplete(1:conservedCharacters);

    %Append ICAWeights to file names and set path for future save to
    %"daughter folder" ICAClean
    newFileName = strcat(fileName, '_Filt(0,1-45).set');
    fileNameRAW = strcat(fileName, '_RAW.set');

    if isempty(strVerify)
        newFilePath = strcat(pathName, 'preProcessing/');
    else
        newFilePath = strcat(pathName, 'preProcessing\');
    end

    %Check if dataset has already been run ICA on
    existsFile = exist ([newFilePath, newFileName], 'file');

    if existsFile ~= 2
        
        close all;
        
        %Initialize EEGLAB, this seems to be necessary in order to get
        %error-free filtering
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

        %Function to load .mff into EEGLAB
        EEG = pop_mffimport([pathName, fileNameComplete], {'classid' 'code' 'description' 'label' 'mffkey_cidx' 'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' 'sourcedevice'});
        EEG = eeg_checkset( EEG );

        EEG = pop_editset(EEG, 'setname', fileNameRAW);
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',fileNameRAW,'filepath',newFilePath);

        %Filter dataset
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET)
        EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',45, 'filtorder', 33000);

        %Append "Filt(0,1-45)" to filename
        EEG = pop_editset(EEG, 'setname', newFileName);
        EEG = eeg_checkset( EEG );

        %Saving new file name to new path
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
        EEG = eeg_checkset( EEG );

        %Purge dataset from memory
        EEG = pop_delset( EEG, [1] );
        ALLEEG = [];
        CURRENTSET = 0;
    end

end

close all;

%Display end message
if Filenum == numel(FilesList)
    displayedMessage = msgbox('Operation Completed');
end
