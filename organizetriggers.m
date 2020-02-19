FilesList = dir([pathName,'*.set']);
Filenum = [];
cyclesRun = 0;

if exist(folderOrganizeTriggers, 'dir') ~= 7
    mkdir (folderOrganizeTriggers);
    foldersCreated(end+1) = {folderOrganizeTriggers};
end

%Loop going from the 1st element in the folder, to the total elements
for Filenum = 1:numel(FilesList)
    
    fileNameComplete = char(FilesList(Filenum).name);
    fileName = fileNameComplete(1:conservedCharacters);
    fileNameOdor = strcat(fileName, '_Odor.set');
    fileNamePlacebo = strcat(fileName, '_Placebo.set');
    
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
        if size(EEG.event,2) ~= EEG.trials
            error(strcat('There are more trigger events than trials (epochs) in', fileNameComplete));
            return
        end
        
        %% Andrea S�nchez Corzo
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
        EEG = pop_editset(EEG, 'setname', fileNameOdor);
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',fileNameOdor,'filepath',folderOrganizeTriggers);
        
        %return to original dataset
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0);
        EEG = eeg_checkset( EEG );
        
        %Select placebo on epochs and save file
        EEG = pop_select( EEG, 'trial',PlaceboOn );
        EEG = pop_editset(EEG, 'setname', fileNamePlacebo);
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',fileNamePlacebo,'filepath',folderOrganizeTriggers);
        
        cyclesRun = cyclesRun + 1;
    end
    
end
close all;