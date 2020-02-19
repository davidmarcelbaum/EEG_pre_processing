% Files will be loaded from intitial dataset folder if .set
% were chosen during fileFormat question and in subfolder
% folderRAW if initial file format was 2 (.mff)
FilesList = dir([pathName,'*.set']);

if exist(folderInterpolInfo, 'dir') ~= 7
    mkdir (folderInterpolInfo);
    foldersCreated(end+1) = {folderInterpolInfo};
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