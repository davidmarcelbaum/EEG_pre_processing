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
    foldersCreated(end+1) = {folderChInterpol};
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
            load '[folderInterpolInfo ChInterpolFile]'
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