% check for script part-specific subfolders in preProcessing
if exist(folderRAW, 'dir') ~= 7 && stepLevel < 1
    mkdir (folderRAW);
    foldersCreated(end+1) = {folderRAW};
end
if exist(folderFilt, 'dir') ~= 7 && stepLevel < 2
    mkdir (folderFilt);
    foldersCreated(end+1) = {folderFilt};
end
if exist(folderReference, 'dir') ~= 7 && stepLevel < 3
    mkdir (folderReference);
    foldersCreated(end+1) = {folderReference};
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