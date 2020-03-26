%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Some prerequisities in order for the script to function %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Since the path to EEGLAB differs between systems, locate EEGLAB and its functions.
locateEeglab = which('eeglab.m');

if ~isempty(locateEeglab)
    
    [folderEEGLAB, ~, ~] = fileparts(locateEeglab);
    
    strcat(folderEEGLAB, filesep, 'functions', filesep, 'adminfunc');
    strcat(folderEEGLAB, filesep, 'functions', filesep, 'popfunc');
    strcat(folderEEGLAB, filesep, 'loadcurry2.1');
    
else
    
    error('EEGLAB not found')
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Beginning of user inputs %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Give here the source folder of the datasets to be imported
pathName = uigetdir(cd,'Choose the folder that contains the datasets');
%[filesPreProcess, pathName] = uigetfile(cd,'Choose one dataset to build pathways','*.*','multiselect','off');

pathName = strcat(pathName, filesep);

%This will deselect steps of the script that are not needed.
chooseScriptParts = {'RAWing, Filtering and/or re-referencing',...
    'Interpolation of noisy channels','ICA','Epoching',...
    'Extract channel interpolation information',...
    'Compute dipoles with Nonlinear least-square fit regression curve',...
    'Organize Triggers','Reject empty channels',...
    'Transform chanlocs.xyz to .elc','Asign dipoles to atlas area'};

[scriptPart,tfParts] = listdlg('PromptString',...
    'What type of pre-processing do you want to perform?',...
    'SelectionMode','single','ListSize',[800,300],...
    'ListString',chooseScriptParts);

%Based on what the user chooses, the import and load functions of the datasets are impacted

chooseFileFormat = {'.set', '.mff', '.cdt'};

if scriptPart == 1
    [fileFormat,~] = listdlg('PromptString',...
        'What is the format of your datasets?',...
        'SelectionMode','single','ListSize',[150,150],...
        'ListString',chooseFileFormat);
    
    fileFormat = chooseFileFormat(fileFormat);
    
else
    fileFormat = '.set';
end


%Extract the base name structure of each dataset in order to later append extensions during saving
dataList = dir(pathName);
dataFormat = find(contains({dataList.name}, fileFormat));

% Some header files have the same data format as files of interest, but
% contain an additional format (ie .cdt.dpa). This line rejects these
idxWrongFormat = contains(extractAfter({dataList(dataFormat).name}, ...
    fileFormat), '.');

dataFormat = dataFormat(~idxWrongFormat);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Setting up environment for script %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check if all information has been provided that will be used in the script
if isempty(pathName) || isempty(fileFormat) || isempty(scriptPart)
    
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
    preProcessingFolder = replace(pathName, extractAfter(pathName, 'preProcessing'), filesep);
else
    if exist([pathName, 'preProcessing'], 'dir') ~= 7
        mkdir (pathName, 'preProcessing');
    end
    preProcessingFolder = strcat(pathName, 'preProcessing', filesep);
end

%Set up folder structures so that each step is saved in separate folder.
folderFiltRef = strcat(preProcessingFolder, 'FiltRef', filesep);
folderChInterpol = strcat(preProcessingFolder, 'ChInterpol', filesep);
folderICAWeights = strcat(preProcessingFolder, 'ICAWeights', filesep);
folderICAClean = strcat(preProcessingFolder, 'ICAClean', filesep);
folderEpochs = strcat(preProcessingFolder, 'Epochs', filesep);
folderSelEpochs = strcat(preProcessingFolder, 'SelectedEpochs', filesep);
folderInterpolInfo = strcat(preProcessingFolder, 'ChannelInterpolation', filesep);
folderDipoles = strcat(preProcessingFolder, 'Dipoles', filesep);
folderOrganizeTriggers = strcat(preProcessingFolder, 'OrganizeTriggers', filesep);
folderRejEmptyChan = strcat(preProcessingFolder, 'RejEmptyChannel', filesep);
folderAtlas = strcat(preProcessingFolder, 'Atlas', filesep);
foldersCreated = {};

%Set up initial stepLevel value so that later, pre-processing of datasets
%is only forward and not reverse
stepLevel = 0;

FiltRef = 1;
ChInterpolated = 2;
SleepExtr = 3;
ICAWeighted = 4;
ICACleaned = 5;
Epoched = 6;
SelEpoched = 7;

%Define stepLevel based on dataset names
%dataMatch = find(contains({dataList.name}, fileFormatTranslation));
%FilesList = dir([pathName,'*.*']);
if contains(string(dataList(dataFormat(1)).name), '_FiltRef')
    stepLevel = FiltRef;
elseif contains(string(dataList(dataFormat(1)).name), '_ChInterpol')
    stepLevel = ChInterpolated;
elseif contains(string(dataList(dataFormat(1)).name), '_SleepExtr')
    stepLevel = SleepExtr;
elseif contains(string(dataList(dataFormat(1)).name), '_ICAWeights')
    stepLevel = ICAWeighted;
elseif contains(string(dataList(dataFormat(1)).name), '_ICAClean')
    stepLevel = ICACleaned;
elseif contains(string(dataList(dataFormat(1)).name), '_Epochs')
    stepLevel = Epoched;
elseif contains(string(dataList(dataFormat(1)).name), '_SelectedEpochs')
    stepLevel = SelEpoched;
end