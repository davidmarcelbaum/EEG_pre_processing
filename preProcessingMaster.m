%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Guidelines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ### This script follows the following pre-processing pipeline:        ###
% . _RAW: conversion to .set format                                     ###
% .. _Filt(0,1-45): Filtering highpass o.1Hz and lowpass 45Hz           ###
% ... _Re-reference: referenced to user-chosen reference                ###
% .... _ChInterpol: Interpolating noisy channels                        ###
% ..... _ICAWeights: ICA has been performed on dataset                  ###
% ...... _ICAClean: Artefactial IC removed                              ###
% ....... _EpochsICAWeights: Cutting dataset into epochs                ###
% ........ _SelectedEpochs: Noisy epochs have been rejected             ###

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
pathName = uigetdir(cd,'Choose the folder that contains the datasets');
%[filesPreProcess, pathName] = uigetfile(cd,'Choose one dataset to build pathways','*.*','multiselect','off');

pathName = strcat(pathName, slashSys);

%This will deselect steps of the script that are not needed.
chooseScriptParts = {'RAWing, Filtering and/or re-referencing','Interpolation of noisy channels','ICA','Epoching','Extract channel interpolation information','Compute dipoles with Nonlinear least-square fit regression curve (currently broken)','Organize Triggers','Reject empty channels','Transform chanlocs.xyz to .elc'};

[scriptPart,tfParts] = listdlg('PromptString','What type of pre-processing do you want to perform?','SelectionMode','single','ListSize',[800,300],'ListString',chooseScriptParts);

%Based on what the user chooses, the import and load functions of the datasets are impacted
switch scriptPart
    case 1
        chooseFileFormat = {'.set','.mff folders'}; %DO NOT CHANGE ORDER OF FORMATS, adding is ok, though !!!
        [fileFormat,tfFiles] = listdlg('PromptString','What is the format of your datasets?','SelectionMode','single','ListSize',[150,150],'ListString',chooseFileFormat);
        fileFormatTranslation = fileFormat;
    otherwise
        fileFormat = 1;
        fileFormatTranslation = fileFormat;
end

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

%Creates preProcessing folder and subfolders only if they do not exist.
%This is essential for saving the datasets later, but to avoid that the script
%will put subfolders in existing preProcessing folder, digging into the folder paths
%too deep and coming out on the other end of Earth: "Buongiorno!".
if contains(pathName, 'preProcessing')
    %preProcessingFolder = replace(pathName,extractAfter(pathName,"preProcessing"),slashSys);
    preProcessingFolder = replace(pathName, extractAfter(pathName, 'preProcessing'), slashSys);
else
    if exist([pathName, 'preProcessing'], 'dir') ~= 7
        mkdir (pathName, 'preProcessing');
    end
    preProcessingFolder = strcat(pathName, 'preProcessing', slashSys);
end

%Set up folder structures so that each step is saved in separate folder.
folderRAW = strcat(preProcessingFolder, 'RAW', slashSys);
folderFilt = strcat(preProcessingFolder, 'Filtered', slashSys);
folderReference = strcat(preProcessingFolder, 'Re-reference', slashSys);
folderChInterpol = strcat(preProcessingFolder, 'ChInterpol', slashSys);
folderICAWeights = strcat(preProcessingFolder, 'ICAWeights', slashSys);
folderICAClean = strcat(preProcessingFolder, 'ICAClean', slashSys);
folderEpochs = strcat(preProcessingFolder, 'Epochs', slashSys);
folderSelEpochs = strcat(preProcessingFolder, 'SelectedEpochs', slashSys);
folderInterpolInfo = strcat(preProcessingFolder, 'ChannelInterpolation', slashSys);
folderDipoles = strcat(preProcessingFolder, 'Dipoles', slashSys);
folderOrganizeTriggers = strcat(preProcessingFolder, 'OrganizeTriggers', slashSys);
folderRejEmptyChan = strcat(preProcessingFolder, 'RejEmptyChannel', slashSys);

%Set up initial stepLevel value so that later, pre-processing of datasets
%is only forward and not reverse
stepLevel = 0;

RAWed = 1;
Filtered = 2;
Rereferenced = 3;
ChInterpolated = 4;
ICAWeighted = 5;
ICACleaned = 6;
Epoched = 7;
SelEpoched = 8;

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
elseif contains(string(dataList(dataMatch(1)).name), '_ICAWeights')
    stepLevel = ICAWeighted;
elseif contains(string(dataList(dataMatch(1)).name), '_ICAClean')
    stepLevel = ICACleaned;
elseif contains(string(dataList(dataMatch(1)).name), '_Epochs')
    stepLevel = Epoched;
elseif contains(string(dataList(dataMatch(1)).name), '_SelectedEpochs')
    stepLevel = SelEpoched;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Integrating last inputs and starting script %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch scriptPart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
        
        % check for script part-specific subfolders in preProcessing
        if exist(folderRAW, 'dir') ~= 7 && stepLevel < 1
            mkdir (folderRAW);
        end
        if exist(folderFilt, 'dir') ~= 7 && stepLevel < 2
            mkdir (folderFilt);
        end
        if exist(folderReference, 'dir') ~= 7 && stepLevel < 3
            mkdir (folderReference);
        end
        
        if stepLevel == 3 || stepLevel > 3
            warning('Your datasets seem to be RAWed, Filtered, and Re-referenced. If you want to run these steps anyway, you have to adapt the section that initializes the "stepLevel" values')
            return
        end
        
        %Load one dataset into EEGLAB. This is necessary for the
        %EEG.chanlocs afterwards (until line 231)
        msgbox('The next step will take a while depending on the size of your first dataset. The EEGLAB window will close automatically. You can close this window.')
        ALLCOM = {};
        ALLEEG = [];
        CURRENTSET = 0;
        EEG = [];
        [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
        
        switch fileFormat
            case 1
                EEG = pop_loadset('filename',dataList(dataMatch(1)).name,'filepath',pathName);
            case 2
                EEG = pop_mffimport([pathName, dataList(dataMatch(1)).name], {'classid' 'code' 'description' 'label' 'mffkey_cidx' 'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' 'sourcedevice'});
        end
        EEG = eeg_checkset( EEG );
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = eeg_checkset( EEG );
        close all;
        
        %Define the channel to be excluded during the referencing step
        if stepLevel < 3
            %referenceChannel = questdlg('Channel used for reference during recording?', ...
            %    'Choose reference', ...
            %    'Common','Specific electrode','Do not know','Do not know');
            
            %if contains(referenceChannel,'Specific electrode')
            %    referenceChannel = str2double(inputdlg({'Number of reference electrode?'},...
            %        'Put a number', [1 50], {'129'})');
            %end
            channelList = {EEG.chanlocs.labels}';
            [rejectedChannelIndex] = listdlg('PromptString',[{'Exclude channels (such as VEO, HEO, M1, M2 or Trigger) from re-ferencing:'} {''} {''} {''}],'ListString', channelList);
        end
        
        %Ask to reject absent channels
        [emptyChannelIndex, emptyChannelAnswer] = listdlg('PromptString',[{'Do you have channels that have NOT been used?'} {''} {''}],'ListString', channelList);
        
        %Ask whether to change channel locations if not present.
        questLocateChannels = [];
        if isempty(EEG.chanlocs(1).X)
            questLocateChannels = questdlg('Do you want to locate channels?','Locate channels','Yes','No','Yes');
            if strcmpi(questLocateChannels, 'Yes')
                [channelLocationsFile, channelLocationsPath] = uigetfile('*.elp','Look for channel locations file',eeglabFolder);
                channelLocationsInfo = strcat(channelLocationsPath, channelLocationsFile);
            end
        end
        
        cyclesRunRAW = 0;
        
        uiwait(msgbox('Starting script after closing this window...'));
        
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
                    
                    if strcmpi(questLocateChannels, 'Yes')
                        EEG=pop_chanedit(EEG, 'lookup',channelLocationsInfo);
                        EEG = eeg_checkset( EEG );
                    end
                    
                    if ~isempty(emptyChannelIndex) || emptyChannelAnswer == 1
                        EEG = pop_select( EEG, 'nochannel', emptyChannelIndex);
                        EEG = eeg_checkset( EEG );
                    end
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderRAW);
                    EEG = eeg_checkset( EEG );
                    
                    cyclesRunRAW = cyclesRunRAW + 1;
                end
            end
            fileFormat = 1; %This will make the script future steps of datasets initially imported as .mff fodlers treat these datasets as .set files
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fileFormat == 1
            
            Filenum = 0;
            cyclesRunFilt = 0;
            cyclesRunReref = 0;
            
            FilesList = dir([pathName,'*.set']);
            
            for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
                
                %Extract the base file name in order to append extensions afterwards
                fileNameComplete = char(FilesList(Filenum).name);
                fileName = fileNameComplete(1:conservedCharacters);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Append _RAW to name of dataset
                newFileName = strcat(fileName, '_RAW.set');
                
                %This avoids re-running RAWing on already RAWed datasets.
                existsFile = exist ([folderRAW, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 && stepLevel < 1 %Checks whether _RAW dataset exists
                    
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
                    
                    EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                    EEG = eeg_checkset( EEG );
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    
                    if strcmpi(questLocateChannels, 'Yes')
                        EEG=pop_chanedit(EEG, 'lookup',channelLocationsInfo);
                        EEG = eeg_checkset( EEG );
                    end
                    
                    if ~isempty(emptyChannelIndex) || emptyChannelAnswer == 1
                        EEG = pop_select( EEG, 'nochannel', emptyChannelIndex);
                        EEG = eeg_checkset( EEG );
                    end
                    
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderRAW);
                    
                    cyclesRunRAW = cyclesRunRAW + 1;
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
                    
                    %Filter dataset
                    if stepLevel == 0
                        EEG = pop_loadset('filename',previousFileName,'filepath',folderRAW);
                    elseif stepLevel == 1
                        EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                    end
                    %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',45, 'filtorder', 33000);
                    
                    %Rename dataset
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    
                    %Save dataset _Filt(0,1-45) to ./preProcessing/Filt/
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderFilt);
                    
                    cyclesRunFilt = cyclesRunFilt + 1;
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
                    %if  referenceChannel == 'Common'
                    %    EEG = pop_reref( EEG, [], 'exclude', rejectedChannelIndex);
                    %elseif referenceChannel == 'Do not know'
                    %    if ~isempty(EEG.ref)
                    %        referenceChannel = erase(EEG.ref, 'E');
                    %        referenceChannel = erase(referenceChanRec, ' ');
                    %        EEG = pop_reref( EEG, [], 'exclude', [rejectedChannelIndex referenceChannel]);
                    %    else
                    %        EEG = pop_reref( EEG, []);
                    %    end
                    %else
                    %    EEG = pop_reref( EEG, [], 'exclude', [rejectedChannelIndex referenceChannel]);
                    %end
                    
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
                    
                    if stepLevel < 2
                        EEG = pop_loadset('filename',previousFileName,'filepath',folderFilt);
                    elseif stepLevel == 2
                        EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                    end
                    % [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = eeg_checkset( EEG );
                    
                    EEG = pop_reref( EEG, [], 'exclude', rejectedChannelIndex);
                    EEG = eeg_checkset( EEG );
                    
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderReference);
                    
                    cyclesRunReref = cyclesRunReref + 1;
                end
                
            end
            close all;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 2 %In case "Interpolation of noisy channels" selected
        
        uiwait(msgbox({'You have chosen Channel Interpolation.';...
            'If you have a text file (single line single space) containing information about the'; ...
            'channels to interpolate, name it as the dataset with the appendix'; ...
            '"_ChInterpol" and save it as .txt. in the same folder as the datasets.'; ...
            'If the channels to interpolate are CB1 or CB2, DO NOT INTERPOLATE THEM'; ...
            'since this will delete channel location information!'}, ...
            'Known channels to interpolate','modal'));
        
        % check for script part-specific subfolders in preProcessing %%%%%%
        if exist(folderChInterpol, 'dir') ~= 7 && stepLevel < 4
            mkdir (folderChInterpol);
        end
        
        % Files will be loaded from intitial dataset folder if .set
        % were chosen during fileFormat question and in subfolder
        % folderRAW if initial file format was 2 (.mff)
        FilesList = dir([pathName,'*.set']);
        
        %This is an attempt to dynamically adapt the script to different file name types and lengths.
        %conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
        %    'Base name structure', 1, FilesList(1,1)));
        %conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
        %   'Base name structure', 1, {FilesList(1).name}));
        
        uiwait(msgbox('Starting script after closing this window...'));
        
        Filenum = 0;
        cyclesRun = 0;
        cyclesInterpolation = 0;
        
        for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
            
            %Extract the base file name in order to append extensions afterwards
            fileNameComplete = char(FilesList(Filenum).name);
            fileName = fileNameComplete(1:conservedCharacters);
            
            % Function for loading
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            ChInterpolFile = strcat(fileName, '_ChInterpolInfo.mat');
            
            %Append _ChInterpol to name of dataset
            newFileName = strcat(fileName, '_ChInterpol.set');
            
            %This avoids re-running RAWing on already RAWed datasets.
            existsFile = exist ([folderChInterpol, newFileName], 'file');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if existsFile ~= 2 && stepLevel < 4 %Checks whether _ChInterpol dataset exists
                
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
                
                EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                
                %Function to look for available text files with channel
                %information inside and load them as "double" array
                if exist([folderInterpolInfo ChInterpolFile], 'file')
                    load [folderInterpolInfo ChInterpolFile];
                    EEG = pop_interp(EEG, [string(interpolatedChan)], 'spherical');
                    EEG = eeg_checkset( EEG );
                    
                    cyclesInterpolation = cyclesInterpolation + 1;
                end
                
                % Function for appending _ChInterpol
                EEG = pop_editset(EEG, 'setname', newFileName);
                
                % Function for saving
                EEG = eeg_checkset( EEG );
                EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderChInterpol);
                
                cyclesRun = cyclesInterpolation;
            end
        end
        close all;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 3 %In case "ICA" selected
        
        % check for script part-specific subfolders in preProcessing %%%%%%
        if exist(folderICAWeights, 'dir') ~= 7 && stepLevel < 5
            mkdir (folderICAWeights);
        end
        
        % Files will be loaded from intitial dataset folder if .set
        % were chosen during fileFormat question and in subfolder
        % folderRAW if initial file format was 2 (.mff)
        FilesList = dir([pathName,'*.set']);
        
        %Load one dataset into EEGLAB. This is necessary for the
        %EEG.chanlocs afterwards (until line 231)
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 4 %In case "Epoching" selected
        
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 5 %In case "Extract channel interpolation information" selected
        
        % Files will be loaded from intitial dataset folder if .set
        % were chosen during fileFormat question and in subfolder
        % folderRAW if initial file format was 2 (.mff)
        FilesList = dir([pathName,'*.set']);
        
        if exist(folderInterpolInfo, 'dir') ~= 7
            mkdir (folderInterpolInfo);
        end
        
        cyclesRun = 0;
        
        uiwait(msgbox('Starting script after closing this window...'));
        
        for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
            
            %Extract the base file name in order to append extensions afterwards
            fileNameComplete = char(FilesList(Filenum).name);
            fileName = fileNameComplete(1:conservedCharacters);
            
            %In order to make this clean, it saves files in a new ICAWeights directory of the mother directory
            ChInterpolFile = strcat(fileName, '_ChInterpolInfo.mat');
            
            %This avoids re-running ICA on datasets that ICA has already been run on.
            existsFile = exist ([pathName, ChInterpolFile], 'file');
            
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
                
                %This will check whether channels had been interpolated
                %in this dataset.
                haveBeenInterpol = strfind(EEG.history,'pop_interp');
                
                if ~isempty(haveBeenInterpol)
                    interpolatedChan = extractBetween(EEG.history, "EEG = pop_interp(EEG, [","], 'spherical'");
                    save([folderInterpolInfo ChInterpolFile], 'interpolatedChan');
                end
                
                cyclesRun = cyclesRun + 1;
            end
        end
        close all;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 6 %In case "Compute dipoles ..." selected
        
        FilesList = dir([pathName,'*.set']);
        
        %Load one dataset into EEGLAB. This is necessary for the
        %EEG.chanlocs afterwards (until line 231)
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
        
        %Search for Head Model (HM)
        % Instead, look for BEM-generated head model [stdHeadModel, stdHeadModelPath] = uigetfile('*.mat','Look for standard head model',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'standard_vol.mat'));
        folderHM = [uigetdir(cd,'Choose folder containing subjects head models *** IN .MAT FORMAT ***'), slashSys];
        FilesListHM = dir([folderHM,'*.mat']);
        
        %Search for standard electrode for 10-20 system
        % Exchanged for "chanLocFileELC" [stdElectrodes, stdElectrodesPath] = uigetfile('*.elc','Look for channel locations file',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'elec', slashSys, 'standard_1020.elc'));
        
        %Search for MRI anatomy folder of subjects
        subjAnatFolder = [uigetdir(cd,'Choose folder containing subjects anatomy *** IN .HDR / .IMG FORMAT ***'), slashSys];
        subjAnat = dir([subjAnatFolder, '*.hdr']);
        
        %Search for channel locations folder of subjects
        chanLocFolder = [uigetdir(cd,'Choose folder containing subjects channel locations *** IN MATLAB .XYZ FORMAT ***'), slashSys];
        chanLocFilesXYZ = dir([chanLocFolder, '*.xyz']);
        chanLocFilesELC = dir([chanLocFolder, '*.elc']);
        
        if exist(folderDipoles, 'dir') ~= 7
            mkdir (folderDipoles);
        end
        
        cyclesRun = 0;
        
        uiwait(msgbox('Starting script after closing this window...'));
        
        for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
            
            %Extract the base file name in order to append extensions afterwards
            fileNameComplete = char(FilesList(Filenum).name);
            fileName = fileNameComplete(1:conservedCharacters);
            
            newFileName = strcat(fileName, '_Dipoles.set');
            
            %This avoids re-running ICA on datasets that ICA has already been run on.
            existsFile = exist ([folderDipoles, newFileName], 'file');
            
            if existsFile ~= 2
                
                %This is important because EEGLAB after completing the task leaves some windows open.
                close all;
                
                EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                
                %Set channel locations based on export from Brainstorm
                %after "fiducialing". Should be saved as Matlab .xyz file.
                %"'rplurchanloc',1" overwrites channel location info with
                %newly provided information
                % *** Please confirm that settings make sense!!! ***
                EEG=pop_chanedit(EEG, 'rplurchanloc',1,'load',[],'load',{[chanLocFolder, chanLocFilesXYZ(Filenum).name] 'filetype' 'autodetect'},'setref',{'1:128' 'average'});
                [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                EEG = eeg_checkset( EEG );
                
                %Compute dipoles on all components of ICA (EEG.icaact),
                %threshold of residual variance set to 100% in order to
                %compute ALL dipoles. Otherwise,
                %EEG.dipfit.model.areadk will not store area
                %information of dipole from atlas of dipolesabove
                %threshold.
                EEG = pop_dipfit_settings( EEG, 'hdmfile',[stdHeadModelPath, stdHeadModel],'coordformat','MNI','mrifile',[subjAnatFolder, subjAnat(Filenum).name],'chanfile',[chanLocFolder, chanLocFilesELC(Filenum).name],'chansel',[1:EEG.nbchan] );
                [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                EEG = pop_multifit(EEG, [1:size(EEG.icaweights,1)] ,'threshold',100,'plotopt',{'normlen' 'on'});
                [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%% This is extracted from the eeg_compatlas.m of the %%%
                %%%% dipfit plugin                                     %%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                function EEG = eeg_compatlas(EEG, varargin)
                
                if nargin < 1
                    help eeg_compatlas;
                    return
                end
                
                if ~isfield(EEG, 'dipfit') || isempty(EEG.dipfit) || ~isfield(EEG.dipfit, 'model') || isempty(EEG.dipfit.model)
                    error('You must run dipole localization first');
                end
                
                % decode options
                % --------------
                g = finputcheck(varargin, ...
                    { 'atlas'      'string'    {'dk' }     'dk';
                    'components' 'integer'   []          [1:size(EEG.icaweights,1)] });
                if isstr(g), error(g); end;
                
                % loading hm file
                hm = [folderHM, FilesListHM(Filenum).name];
                
                if isdeployed
                    stdHM = load('-mat', fullfile( ctfroot, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
                    if ~exist(meshfile)
                        error(sprintf('headplot(): deployed mesh file "%s" not found\n','head_modelColin27_5003_Standard-10-5-Cap339.mat'));
                    end
                else
                    p  = fileparts(which('eeglab.m'));
                    stdHM = load('-mat', fullfile( p, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
                end
                
                % coord transform to the HM file space
                if strcmpi(EEG.dipfit.coordformat, 'MNI')
                    tf = traditionaldipfit([0.0000000000 -26.6046230000 -46.0000000000 0.1234625600 0.0000000000 -1.5707963000 1000.0000000000 1000.0000000000 1000.0000000000]);
                elseif strcmpi(EEG.dipfit.coordformat, 'spherical')
                    tf = traditionaldipfit([-5.658258      1.039259     -42.80596   -0.00981033    0.03362692   0.004391199      860.8199      926.6112       858.162]);
                else
                    error('Unknown coordinate format')
                end
                tfinv = pinv(tf); % the transformation is from HM to MNI (we need to invert it)
                
                % scan dipoles
                fprintf('Looking up brain area in the Desikan-Killiany Atlas\n');
                for iComp = g.components(:)'
                    if size(EEG.dipfit.model(iComp).posxyz,1) == 1
                        atlascoord = tfinv * [EEG.dipfit.model(iComp).posxyz 1]';
                        
                        % find close location in Atlas
                        distance = sqrt(sum((hm.Vertices-repmat(atlascoord(1:3)', [size(hm.Vertices,1) 1])).^2,2));
                        
                        % compute distance to each brain area
                        [~,selectedPt] = min( distance );
                        area = stdHM.atlas.colorTable(selectedPt);
                        if area > 0
                            EEG.dipfit.model(iComp).areadk = stdHM.atlas.label{area};
                        else
                            EEG.dipfit.model(iComp).areadk = 'no area';
                        end
                        
                        fprintf('Component %d: area %s\n', iComp, EEG.dipfit.model(iComp).areadk);
                    else
                        if ~isempty(EEG.dipfit.model(iComp).posxyz)
                            fprintf('Component %d: cannot find brain area for bilateral dipoles\n', iComp);
                        else
                            fprintf('Component %d: no location (RV too high)\n', iComp);
                        end
                    end
                end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                EEG = eeg_checkset( EEG );
                EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderDipoles);
                EEG = eeg_checkset( EEG );
                
                cyclesRun = cyclesRun + 1;
            end
            
        end
        close all;
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 7 %In case "Organize Triggers" selected
        
        FilesList = dir([pathName,'*.set']);
        Filenum = [];
        cyclesRun = 0;
        
        if exist(folderOrganizeTriggers, 'dir') ~= 7
            mkdir (folderOrganizeTriggers);
        end
        
        %Loop going from the 1st element in the folder, to the total elements
        for Filenum = 1:numel(FilesList)
            
            fileNameComplete = char(FilesList(Filenum).name);
            fileName = fileNameComplete(1:conservedCharacters);
            fileNameOdor = strcat(fileName, '_OdorOn.set');
            fileNamePlacebo = strcat(fileName, '_PlaceboOn.set');
            
            %This avoids re-running ICA on datasets that ICA has already been run on.
            existsFile = exist ([folderOrganizeTriggers, fileNameOdor], 'file');
            if existsFile ~= 2
                
                %Initializes the variables EEG and ALLEEG
                ALLCOM = {};
                ALLEEG = [];
                CURRENTSET = 0;
                EEG = [];
                [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
                
                %load data set
                EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                
                % Some epochs might contain two trigger events. In this
                % case, the script will not work
                if ~istrue (size(EEG.event,2) == EEG.trials)
                    error(strcat('There are more trigger events than trials (epochs) in', fileNameComplete));
                    return
                end
                
                
                %%%%%%%%run OrganizeTrigggers%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % Separar por DIN1 y DIN2
                
                All_DIN1 = find(strcmp({ALLEEG(1).event.code},'DIN1'));
                
                All_DIN2 = find(strcmp({ALLEEG(1).event.code},'DIN2'));
                
                
                % Separar por pares e impares
                
                get_cidx= {ALLEEG(1).event.mffkey_cidx};
                
                Placebo_Epochs = find(mod(str2double(get_cidx),2)==0);
                Odor_Epochs = find(mod(str2double(get_cidx),2)~= 0);
                
                [PlaceboOn] = intersect(All_DIN1,Placebo_Epochs);
                [OdorOn] = intersect(All_DIN1,Odor_Epochs);
                
                
                %%%%%separate data sets%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %Select odor on epochs
                EEG = pop_select( EEG, 'trial',OdorOn );
                %Save new data set and file
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',fileNameOdor);
                EEG = eeg_checkset( EEG );
                EEG = pop_saveset( EEG, 'filename',fileNameOdor,'filepath',folderOrganizeTriggers);
                
                %return to original dataset
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0);
                EEG = eeg_checkset( EEG );
                
                %Select placebo on epochs and save file
                EEG = pop_select( EEG, 'trial',PlaceboOn );
                EEG = pop_saveset( EEG, 'filename',fileNamePlacebo,'filepath',folderOrganizeTriggers);
                
                cyclesRun = cyclesRun + 1;
            end
            
        end
        close all;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 8 %In case "Reject empty channels" selected
        
        FilesList = dir([pathName,'*.set']);
        Filenum = [];
        cyclesRun = 0;
        
        if exist(folderRejEmptyChan, 'dir') ~= 7
            mkdir (folderRejEmptyChan);
        end
        
        %Loop going from the 1st element in the folder, to the total elements
        for Filenum = 1:numel(FilesList)
            
            close all;
            
            fileNameComplete = char(FilesList(Filenum).name);
            fileName = fileNameComplete(1:conservedCharacters);
            newFileName = strcat(fileName, '_ChanRej.set');
            
            existsFile = exist ([folderRejEmptyChan, newFileName], 'file');
            if existsFile ~= 2
                
                %Initializes the variables EEG and ALLEEG
                ALLCOM = {};
                ALLEEG = [];
                CURRENTSET = 0;
                EEG = [];
                [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
                
                %load data set
                EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                
                channelNum = 0;
                noChan = {};
                
                for channelNum = 1:size(EEG.data,1)
                    if istrue(EEG.data(channelNum) == zeros)
                        noChan(end+1) = {EEG.urchanlocs(channelNum).labels};
                    end
                end
                
                if ~isempty(noChan)
                    %Reject channel
                    EEG = pop_select( EEG, 'nochannel',noChan);
                    
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderRejEmptyChan);
                    EEG = eeg_checkset( EEG );
                    
                    cyclesRun = cyclesRun + 1;
                end
                
            end
        end
        close all;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 9 %In case 'Transform chanlocs.xyz to .elc' selected
        
        FilesList = dir([pathName,'*.xyz']);
        Filenum = [];
        cyclesRun = 0;
        
        chanLocFile = char(FilesList(Filenum).name);
        
        chanLocsXYZ = readtable([pathName, chanLocFile],'FileType','text');
        
        chanLocsELC = {};
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    otherwise %If nothing has been selected or "Cancel" button clicked
        warning('No option for pre-processing has been chosen');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% End of script execution %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Filenum == numel(FilesList) && Filenum ~= 0
    switch scriptPart
        case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
            msgbox({'Operation Completed',...
                'Script RAWed ' string(cyclesRunRAW) ' of ' string(numel(FilesList)) ' datasets',...
                'Script filtered ' string(cyclesRunFilt) ' of ' string(numel(FilesList)) ' datasets',...
                'Script re-referenced ' string(cyclesRunReref) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderRAW,...
                folderFilt,...
                folderReference});
        case 2 %In case "Interpolation of noisy channels" selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderChInterpol});
        case 3 %In case "ICA" selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderICAWeights});
        case 4 %In case "Epoching" selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderEpochs});
        case 5 %In case "Extract channel interpolation information" selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderInterpolInfo});
        case 6 %In case "Compute dipoles ..." selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderDipoles});
        case 7 %In case "Organize Triggers" selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderOrganizeTriggers});
        case 8 %In case empty channels rejection selected
            msgbox({'Operation Completed',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in:',...
                folderRejEmptyChan});
    end
elseif Filenum == 0
    msgbox({'The folder you pointed to does not seem to contain any datasets.'});
end
