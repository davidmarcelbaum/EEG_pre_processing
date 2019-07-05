%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Guidelines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ### This script follows the following pre-processing pipeline:        ###
% . _RAW: conversion to .set format                                     ###
% .. _Filt(0,1-45): Filtering highpass o.1Hz and lowpass 45Hz           ###
% ... _Re-reference: referenced to user-chosen reference                ###
% .... _ChInterpol: Interpolating noisy channels                        ###
% ..... _Epochs: Cutting dataset into epochs                            ###
% ...... _SelectedEpochs: Noisy epochs have been rejected               ###
% ....... _ICAWeights: ICA has been performed on dataset                ###
% ........ _ICAClean: Artefactial IC removed                            ###

% ### This script will proecss ALL datasets of the same type of a given ###
% ### folder. Many options will automatically be determined by the first###
% ### dataset the script encounters. Be sure to isolate your datasets!  ###


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Some prerequisities in order for the script to function %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
%Since the path to EEGLAB differs between systems, locate EEGLAB and its functions.
locateEeglab = which('eeglab.m');
eeglabFolder = erase(locateEeglab, 'eeglab.m');

%Determines which system MAtlab runs on and set slash accordingly since it differs Windows vs
%Unix-like. The slash is used a lot afterwards, so best to define here.
if contains(computer,'PCWIN') == 1
    slashSys = '\';
else
    slashSys = '/';
end

if isempty(locateEeglab)
    functionsEEGLAB = uigetdir(matlabroot,'Point to the folder "functions" of EEGLAB');
    
    addpath(strcat(functionsEEGLAB, slashSys, 'adminfunc', slashSys));
    addpath(strcat(functionsEEGLAB, slashSys, 'popfunc', slashSys));
    
else
    addpath(strcat(eeglabFolder, 'functions', slashSys,'popfunc', slashSys));
    addpath(strcat(eeglabFolder, 'functions', slashSys,'adminfunc', slashSys));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Beginning of user inputs %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%Give here the source folder of the datasets to be imported
pathName = uigetdir(matlabroot,'Choose the folder that contains the datasets');

pathName = strcat(pathName, slashSys);

%Based on what the user chooses, the import and load functions of the datasets are impacted
chooseFileFormat = {'.set','.mff folders'}; %DO NOT CHANGE ORDER OF FORMATS, adding is ok, though !!!

[fileFormat,tfFiles] = listdlg('PromptString','What is the format of your datasets?','SelectionMode','single','ListSize',[150,150],'ListString',chooseFileFormat);
fileFormatTranslation = fileFormat;

%Translate the indices of the fileFormat back to strings. This string is
%used to search for files in the folder that match the file format. For
%convenience in later parts of the script, I created a new variable
%"fileFormatTranslation".
switch fileFormatTranslation
    case 1
        fileFormatTranslation = '.set';
    case 2
        fileFormatTranslation = '.mff';
end

%Extract the base name structure of each dataset in order to later append extensions during saving
dataList = dir(pathName);
dataMatch = find(contains({dataList.name}, fileFormatTranslation));

conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
    'Base name structure', 1, cellstr(dataList(dataMatch(1)).name)));

%This will deselect steps of the script that are not needed.
chooseScriptParts = {'RAWing, Filtering and/or re-referencing','Interpolation of noisy channels','Epoching','ICA'};

[scriptPart,tfParts] = listdlg('PromptString','What do you want to do with the files in the selected folder?','SelectionMode','single','ListSize',[500,150],'ListString',chooseScriptParts);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Setting up environment for script %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check if all information has been provided that will be used in the script
if ~isempty(pathName) && ~isempty(fileFormat) && ~isempty(conservedCharacters) && ~isempty(scriptPart)

else
    %End the script if information is missing
    warning('Some information necessary for the script is missing! Run the script again and provide all information.')
    return
end

%Matlab seems to scan script outside of if else conditions and complains
%that at end of script, FilesList and Filenum are not defined.
Filenum = 0;
FilesList = {};

%Creates preProcessing folder and subfolders if they don't not exist. This is essential for saving the datasets later
existsPreProcessing = exist([pathName, 'preProcessing'], 'dir');
if existsPreProcessing ~= 7
    mkdir (pathName, 'preProcessing');
end
preProcessingFolder = strcat(pathName, 'preProcessing', slashSys);

folderRAW = strcat(preProcessingFolder, 'RAW', slashSys);
folderFilt = strcat(preProcessingFolder, 'Filtered', slashSys);
folderReference = strcat(preProcessingFolder, 'Re-reference', slashSys);
folderChInterpol = strcat(preProcessingFolder, 'ChInterpol', slashSys);
folderEpochs = strcat(preProcessingFolder, 'Epochs', slashSys);
folderSelEpochs = strcat(preProcessingFolder, 'SelectedEpochs', slashSys);
folderICAWeights = strcat(preProcessingFolder, 'ICAWeights', slashSys);
folderICAClean = strcat(preProcessingFolder, 'ICAClean', slashSys);

%Set up initial stepLevel value so that later, pre-processing of datasets
%is only forward and not reverse
stepLevel = 0;
RAWed = 1;
Filtered = 2;
Rereferenced = 3;
ChInterpolated = 4;
Epoched = 5;
SelEpoched = 6;
ICAWeighted = 7;
ICACleaned = 8;

%Define stepLevel based on dataset names
%dataMatch = find(contains({dataList.name}, fileFormatTranslation));
%FilesList = dir([pathName,'*.*']);

if contains(string(dataList(dataMatch(1)).name), '_RAW')
    stepLevel = RAWed;
elseif contains(string(dataList(dataMatch(1)).name), '_Filt')
    stepLevel = Filtered;
elseif contains(string(dataList(dataMatch(1)).name), '_Re-reference')
    stepLevel = Rereferenced;
elseif contains(string(dataList(dataMatch(1)).name), '_ChInterpol')
    stepLevel = ChInterpolated;
elseif contains(string(dataList(dataMatch(1)).name), '_Epochs')
    stepLevel = Epoched;
elseif contains(string(dataList(dataMatch(1)).name), '_SelectedEpochs')
    stepLevel = SelEpoched;
elseif contains(string(dataList(dataMatch(1)).name), '_ICAWeights')
    stepLevel = ICAWeighted;
elseif contains(string(dataList(dataMatch(1)).name), '_ICAClean')
    stepLevel = ICACleaned;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch scriptPart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
        
        % check for script part-specific subfolders in preProcessing %%%%%%
        if exist(folderRAW, 'dir') ~= 7 && stepLevel < 1
            mkdir (folderRAW);
        end
        if exist(folderFilt, 'dir') ~= 7 && stepLevel < 2
            mkdir (folderFilt);
        end
        if exist(folderReference, 'dir') ~= 7 && stepLevel < 3
            mkdir (folderReference);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fileFormat == 2 %Import steps for .mff folder datasets and saving as set
           
            FilesList = dir([pathName,'*.mff']);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
                
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
                
                %Extract the base file name in order to append extensions afterwards
                fileNameComplete = char(FilesList(Filenum).name);
                fileName = fileNameComplete(1:conservedCharacters);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Append _RAW to name of dataset
                newFileName = strcat(fileName, '_RAW.set');
                
                %This avoids re-running ICA on datasets that ICA has already been run on.
                existsFile = exist ([folderRAW, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Function to import .mff folder into EEGLAB
                    EEG = pop_mffimport([pathName, fileNameComplete], {'classid' 'code' 'description' 'label' 'mffkey_cidx' 'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' 'sourcedevice'});
                    EEG = eeg_checkset( EEG );
                    
                    %Stores daataset in first (0) slot.
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                    EEG = eeg_checkset( EEG );
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderRAW);
                    EEG = eeg_checkset( EEG );
                end
            end
            fileFormat = 1; %This will make the script future steps of datasets initially imported as .mff fodlers treat these datasets as .set files
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fileFormat == 1
            
            %This is important because EEGLAB after completing the task leaves some windows open.
            close all;
            
            % Files will be loaded from intitial dataset folder if .set
            % were chosen during fileFormat question and in subfolder
            % folderRAW if initial file format was 2 (.mff).
            if stepLevel == 0
                FilesList = dir([folderRAW,'*.set']);
            elseif stepLevel == 1
                FilesList = dir([pathName,'*.set']);
            end
            
            %Initializes the variables EEG and ALLEEG that are needed later. For some reason,
            %the functions work better when EEGLAB initializes the variables itself, which is
            %why I added the last line.
            ALLCOM = {};
            ALLEEG = [];
            CURRENTSET = 0;
            EEG = [];
            [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Filenum = 0;
            for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
                
                %Extract the base file name in order to append extensions afterwards
                fileNameComplete = char(FilesList(Filenum).name);
                fileName = fileNameComplete(1:conservedCharacters);
                
                %This is important because EEGLAB after completing the task leaves some windows open.
                close all;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Append _RAW to name of dataset
                newFileName = strcat(fileName, '_RAW.set');
                
                %This avoids re-running RAWing on already RAWed datasets.
                existsFile = exist ([folderRAW, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 && stepLevel < 1 %Checks whether _RAW dataset exists
                    
                    EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                    EEG = eeg_checkset( EEG );
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderRAW);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Exchange _RAW with _Filt(0,1-45) and append
                %"Filt(0,1-45)" to filename and set new file paths for
                %saving after filtering
                newFileName = strcat(fileName, '_Filt(0,1-45).set');
                previousFileName = strcat(fileName, '_RAW.set');
                
                %This avoids re-filtering already filtered datasets.
                existsFile = exist ([folderFilt, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 && stepLevel < 2 %Checks whether _Filt(0,1-45) dataset exists
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Filter dataset
                    if stepLevel == 0
                        EEG = pop_loadset('filename',previousFileName,'filepath',folderRAW);
                    elseif stepLevel == 1
                        EEG = pop_loadset('filename',fileName,'filepath',pathName);
                    end
                    %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',45, 'filtorder', 33000);
                    
                    %Rename dataset
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    
                    %Save dataset _Filt(0,1-45) to ./preProcessing/Filt/
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderFilt);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Exchange _Filt with _Re-reference and append
                %"Re-reference" to filename and set new file paths for
                %saving after filtering
                newFileName = strcat(fileName, '_Re-reference.set');
                previousFileName = strcat(fileName, '_Filt(0,1-45).set');
                
                %This avoids re-filtering already filtered datasets.
                existsFile = exist ([folderReference, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 && stepLevel < 3 %Checks whether _Re-reference dataset exsists
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Re-reference to average excluding the electrode used for reference DURING recording.
                    referenceChanRec = erase(EEG.ref, 'E');
                    referenceChanRec = erase(referenceChanRec, ' ');
                    EEG = pop_reref( EEG, [],'exclude',referenceChanRec);
                    
                    if stepLevel == 1
                        EEG = pop_loadset('filename',previousFileName,'filepath',folderFilt);
                    elseif stepLevel == 2
                        EEG = pop_loadset('filename',fileName,'filepath',pathName);
                    end
                    % [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = eeg_checkset( EEG );
                    
                    %Rename and save the dataset in "./preProcessing/RAW/" folder
                    %Exchange _RAW with _Filt(0,1-45) and append "Filt(0,1-45)" to filename
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderReference);
                end
            end
        end
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %In case "Interpolation of noisy channels" selected
    case 2
        
        uiwait(msgbox({'You have chosen Channel Interpolation.';...
            'If you have a text file containing information about the'; ...
            'channels to interpolate, name it as the dataset with the appendix'; ...
            '"_ChInterpol" and save it as .txt. in the same folder as the datasets.' }, ...
            'Known channels to interpolate','modal'));
        
        % check for script part-specific subfolders in preProcessing %%%%%%
        if exist(folderChInterpol, 'dir') ~= 7 && stepLevel < 4
            mkdir (folderChInterpol);
        end
        
        if fileFormat == 1
            
            %This is important because EEGLAB after completing the task leaves some windows open.
            close all;
            
            % Files will be loaded from intitial dataset folder if .set
            % were chosen during fileFormat question and in subfolder
            % folderRAW if initial file format was 2 (.mff)
            FilesList = dir([pathName,'*.set']);
            
            %Initializes the variables EEG and ALLEEG that are needed later. For some reason,
            %the functions work better when EEGLAB initializes the variables itself, which is
            %why I added the last line.
            ALLCOM = {};
            ALLEEG = [];
            CURRENTSET = 0;
            EEG = [];
            [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
            
            Filenum = 0;
            for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
                
                %Extract the base file name in order to append extensions afterwards
                fileNameComplete = char(FilesList(Filenum).name);
                fileName = fileNameComplete(1:conservedCharacters);
                
                % Function for loading
                EEG = pop_loadset('filename',fileName,'filepath',pathName);
                EEG = eeg_checkset( EEG );
                
                %Function to look for available text files with channel information inside
                
                % Function for processing
                
                % Function for setname
                EEG = pop_editset(EEG, 'setname', newFileName);
                EEG = eeg_checkset( EEG );
                
                % Function for saving
                EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderReference);
                
                %Function to save information of which channels have been interpolated.
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %In case "Epoching" selected
    case 3
        
        %Do not delete the transpose at the end of the function.
        epochDimensions = str2double(inputdlg({'Seconds before trigger?','Seconds after trigger?'},...
            'Define epoch size', [1 50], {'-3';'7'})');
        if epochDimensions(1) > 0
            epochDimensions(1) = -epochDimensions(1);
        end
        if epochDimensions(2) < 0
            epochDimensions(2) = -epochDimensions(2);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %In case "ICA" selected
        %case 4
        
        
         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %If nothing has been selected or "Cancel" button clicked
    otherwise
        warning('No option has been choosen');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% End of script execution %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Filenum == numel(FilesList)
    msgbox('Operation Completed');
end