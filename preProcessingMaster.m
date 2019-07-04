%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Some prerequisities in order for the script to function %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
%Since the path to EEGLAB differs between systems, locate EEGLAB and its functions.
locateEeglab = which('eeglab.m');
eeglabFolder = erase(locateEeglab, 'eeglab.m');

%Determine which system Matlab runs on in order to avoid problems with forward/backward slashs in Windows vs Unix-like.
strSystem = computer;

%Point Matlab to the EEGLAB functions in order to be be able to call them later by adding the paths with Windows-specific "\".
strVerify = strfind(strSystem,'PCWIN');

if isempty(locateEeglab)
    functionsEEGLAB = uigetdir(matlabroot,'Point to the folder "functions" of EEGLAB');

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% End of prerequisities %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Beginning of user inputs %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%Give here the source folder of the datasets to be imported
pathName = uigetdir(matlabroot,'Choose the folder that contains the datasets');
if isempty(strVerify)
    pathName = strcat(pathName, '/');
else
    pathName = strcat(pathName, '\');
end

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
chooseScriptParts = {'RAWing, Filtering and re-referencing','Interpolation of noisy channels','Epoching','ICA'};

[scriptPart,tfParts] = listdlg('PromptString','What do you want to do with the files in the selected folder?','SelectionMode','single','ListSize',[500,150],'ListString',chooseScriptParts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% End of user inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Beginning script execution %%%%%%%%%%%%%%%%%%%%%%%%
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

%Creates preProcessing folder and subfolders they don't not exist. This is essential for saving the datasets later
existsPreProcessing = exist([pathName, 'preProcessing'], 'dir');
if existsPreProcessing ~= 7
    mkdir (pathName, 'preProcessing');
    if isempty(strVerify)
        preProcessingFolder = strcat(pathName, 'preProcessing/');
    else
        preProcessingFolder = strcat(pathName, 'preProcessing\');
    end
else
    if isempty(strVerify)
        preProcessingFolder = strcat(pathName, 'preProcessing/');
    else
        preProcessingFolder = strcat(pathName, 'preProcessing\');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch scriptPart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 1 %In case "RAWing, Filtering and re-referencing" selected %%%%%%%
        
        % check for script part-specific subfolders in preProcessing %%%%%%
        existSubFoldRAW = exist([preProcessingFolder, 'RAW'], 'dir');
        existSubFoldFilt = exist([preProcessingFolder, 'Filt'], 'dir');
        existSubFoldRereference = exist([preProcessingFolder, 'Re-reference'], 'dir');
    
        if isempty(strVerify)
            if existSubFoldRAW ~= 7
                mkdir (preProcessingFolder, 'RAW/');
            end
            
            if existSubFoldFilt ~= 7
            mkdir (preProcessingFolder, 'Filt/');
            end
            
            if existSubFoldRereference ~= 7
            mkdir (preProcessingFolder, 'Re-reference/');
            end
            
        else
            if existSubFoldRAW ~= 7
            mkdir (preProcessingFolder, 'RAW\');
            end
            
            if existSubFoldFilt ~= 7
            mkdir (preProcessingFolder, 'Filt\');
            end
            
            if existSubFoldRereference ~= 7
            mkdir (preProcessingFolder, 'Re-reference\');
            end
        end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
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
                
                %Again Windows-specific
                if isempty(strVerify)
                    newFilePath = strcat(preProcessingFolder, 'RAW/');
                else
                    newFilePath = strcat(preProcessingFolder, 'RAW\');
                end
                
                %This avoids re-running ICA on datasets that ICA has already been run on.
                existsFile = exist ([newFilePath, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 %Checks whether _RAW dataset exists
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                    %Function to import .mff folder into EEGLAB
                    filePathAndName = [pathName, fileNameComplete];
                    EEG = pop_mffimport(filePathAndName, {'classid' 'code' 'description' 'label' 'mffkey_cidx' 'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' 'sourcedevice'});
                    EEG = eeg_checkset( EEG );
                    
                    %Stores daataset in first (0) slot.
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                    EEG = eeg_checkset( EEG );
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
                    EEG = eeg_checkset( EEG );
                end
            end
        end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            if fileFormat == 1 | fileFormat == 2 %loading and preprocessing of .set datasets. If .mff folder were chosen as file formats, they are now handled like usual .set datasets
            
            %This is important because EEGLAB after completing the task leaves some windows open.
            close all;
           
            if fileFormat == 2
                FilesList = dir([newFilePath,'*.mff']);
            elseif fileFormat == 1
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
                
                %Again Windows-specific
                if isempty(strVerify)
                    newFilePath = strcat(preProcessingFolder, 'RAW/');
                else
                    newFilePath = strcat(preProcessingFolder, 'RAW\');
                end
                
                %This avoids re-running RAWing on already RAWed datasets.
                existsFile = exist ([newFilePath, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 %Checks whether _RAW dataset exists
                    
                    EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                    EEG = eeg_checkset( EEG );
                    
                    if isempty(strVerify)
                        newFilePath = strcat(preProcessingFolder, 'RAW/');
                    else
                        newFilePath = strcat(preProcessingFolder, 'RAW\');
                    end
                    
                    %Rename the dataset with _RAW appendix and save to preProcessing folder
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Exchange _RAW with _Filt(0,1-45) and append
                %"Filt(0,1-45)" to filename and set new file paths for
                %saving after filtering
                newFileName = strcat(fileName, '_Filt(0,1-45).set');
                %Again Windows-specific
                if isempty(strVerify)
                    newFilePath = strcat(preProcessingFolder, 'Filt/');
                else
                    newFilePath = strcat(preProcessingFolder, 'Filt\');
                end
                
                %This avoids re-filtering already filtered datasets.
                existsFile = exist ([newFilePath, newFileName], 'file');
                
                EEG = pop_loadset('filename',fileNamePreviousStep,'filepath',preProcessingFolderPreviousStep);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 %Checks whether _Filt(0,1-45) dataset exists
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Filter dataset
                    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',45, 'filtorder', 33000);

                    %Rename dataset
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    
                    %Save dataset _Filt(0,1-45) to ./preProcessing/Filt/
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Exchange _Filt with _Re-reference and append
                %"Re-reference" to filename and set new file paths for
                %saving after filtering
                newFileName = strcat(fileName, '_Re-reference.set');
                %Again Windows-specific
                if isempty(strVerify)
                    newFilePath = strcat(preProcessingFolder, 'Re-reference/');
                else
                    newFilePath = strcat(preProcessingFolder, 'Re-reference\');
                end
                
                %This avoids re-filtering already filtered datasets.
                existsFile = exist ([newFilePath, newFileName], 'file');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if existsFile ~= 2 %Checks whether _Re-reference dataset exsists
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Re-reference to average excluding the electrode used for reference DURING recording.
                    referenceChanRec = erase(EEG.ref, 'E');
                    referenceChanRec = erase(referenceChanRec, ' ');
                    EEG = pop_reref( EEG, [],'exclude',referenceChanRec);
                    
                    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                    EEG = eeg_checkset( EEG );
                    
                    %Rename and save the dataset in "./preProcessing/RAW/" folder
                    %Exchange _RAW with _Filt(0,1-45) and append "Filt(0,1-45)" to filename
                    EEG = pop_editset(EEG, 'setname', newFileName);
                    EEG = eeg_checkset( EEG );
                    EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
                end
            end
        end
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %In case "Interpolation of noisy channels" selected
    %case 2
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %In case "Epoching" selected
    %case 3
        
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
%if Filenum == numel(FilesList)
%    displayedMessage = msgbox('Operation Completed');
%end