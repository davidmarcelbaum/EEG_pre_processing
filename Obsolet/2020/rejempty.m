FilesList = dir([pathName,'*.set']);
Filenum = [];
cyclesRun = 0;

if exist(folderRejEmptyChan, 'dir') ~= 7
    mkdir (folderRejEmptyChan);
    foldersCreated(end+1) = {folderRejEmptyChan};
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