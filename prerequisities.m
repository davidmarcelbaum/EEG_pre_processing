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