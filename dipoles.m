FilesList = dir([pathName,'*.set']);

%Load one dataset into EEGLAB. This is necessary for the
%EEG.chanlocs afterwards (until line 231)
if ~exist('startPointScript', 'var') || strcmp(startPointScript,'Yes')
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
    
    %Search for Head Model (HM): Standard and cortex. The latter is
    %actually used for atlas-to-dipole area assignation. The first is just
    %used for co-registration of electrodes on headmodel --> not needed
    %here, already done in Brainstorm.
    [stdHeadModel, stdHeadModelPath] = uigetfile('*.mat','Look for standard head model',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'standard_vol.mat'));
    folderHM = strcat([uigetdir(cd,'Choose folder containing subjects head models for cortex or brainstem *** IN .MAT FORMAT ***'), slashSys]);
    FilesListHM = dir([folderHM,'*.mat']);
    
    %Search for standard electrode for 10-20 system
    % Exchanged for "chanLocFileELC" [stdElectrodes, stdElectrodesPath] = uigetfile('*.elc','Look for channel locations file',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'elec', slashSys, 'standard_1020.elc'));
    
    %Search for MRI anatomy folder of subjects
    subjAnatFolder = [uigetdir(folderHM,'Choose folder containing subjects anatomy *** IN .HDR / .IMG FORMAT ***'), slashSys];
    subjAnat = dir([subjAnatFolder, '*.hdr']);
    
    %Search for channel locations folder of subjects
    chanLocFolder = [uigetdir(subjAnatFolder,'Choose folder containing subjects channel locations *** IN BOTH .ELC AND .XYZ FORMAT ***'), slashSys];
    chanLocFilesXYZ = dir([chanLocFolder, '*.xyz']);
    chanLocFilesELC = dir([chanLocFolder, '*.elc']);
    
    atlasComput = questdlg('Which atlas will be used for dipole fitting?', ...
        'Choose atlas', ...
        'Desikan-Killiany','Automated Anatomical Labeling','Desikan-Killiany');
    if isempty(atlasComput)
        error('Must choose atlas');
    else
        fprintf('Will use the %s atlas', atlasComput);
    end
    
    if ~istrue(size(FilesList,1) == 2*size(FilesListHM,1)) || ~istrue(size(FilesList,1) == 2*size(subjAnat,1)) || ~istrue(size(FilesList,1) == 2*size(chanLocFilesXYZ,1)) || ~istrue(size(FilesList,1) == 2*size(chanLocFilesELC,1))
        warning('HAVE FOUND MISMATCH BETWEEN NUMBER OF DATASETS AND NUMBER OF HEAD MODELS, ANATOMY OR CHANNEL LOCATION FILES!')
    end
    
end

if exist(folderDipoles, 'dir') ~= 7
    mkdir (folderDipoles);
end

cyclesRun = 0;

uiwait(msgbox('Starting script after closing this window...'));

for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
    
    %This avoids exporting anatomy files for same subjects twice
    %for each dataset. realFilenum will be used for calling the
    %head models, mri and channel locations.
    if contains(FilesList(Filenum).name,'Placebo')
        realFilenum = Filenum -1;
    else
        realFilenum = Filenum;
    end
    
    %Extract the base file name in order to append extensions afterwards
    fileNameComplete = char(FilesList(Filenum).name);
    fileName = fileNameComplete(1:conservedCharacters);
    
    newFileName = strcat(fileName, '_Dipoles.set');
    
    %This avoids re-running ICA on datasets that ICA has already been run on.
    existsFile = exist ([folderDipoles, newFileName], 'file');
    
    if existsFile ~= 2
        
        %This is important because EEGLAB after completing the task leaves some windows open.
        close all;
        
        ALLCOM = {};
        ALLEEG = [];
        CURRENTSET = 0;
        EEG = [];
        [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
        
        EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        
        %Set channel locations based on export from Brainstorm
        %after "fiducialing". Should be saved as Matlab .xyz file.
        %"'rplurchanloc',1" overwrites channel location info with
        %newly provided information
        % *** Please confirm that settings make sense!!! ***
        EEG=pop_chanedit(EEG, 'rplurchanloc',1,'load',[],'load',{[chanLocFolder, chanLocFilesXYZ(realFilenum).name] 'filetype' 'autodetect'},'setref',{'1:128' 'average'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
        
        %Compute dipoles on all components of ICA (EEG.icaact),
        %threshold of residual variance set to 100% in order to
        %compute ALL dipoles. Otherwise,
        %EEG.dipfit.model.areadk will not store area
        %information of dipole from atlas of dipolesabove
        %threshold.
        EEG = pop_dipfit_settings( EEG, 'hdmfile',[stdHeadModelPath, stdHeadModel],'coordformat','MNI','mrifile',[subjAnatFolder, subjAnat(realFilenum).name],'chanfile',[chanLocFolder, chanLocFilesELC(realFilenum).name],'chansel',[1:EEG.nbchan] );
        %EEG = pop_dipfit_settings( EEG, 'hdmfile',[folderHM, FilesListHM(realFilenum).name],'coordformat','MNI','mrifile',[subjAnatFolder, subjAnat(realFilenum).name],'chanfile',[chanLocFolder, chanLocFilesELC(realFilenum).name],'chansel',[1:EEG.nbchan] );
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        %The next line assigns areas to the dipoles because the functions
        %calls for the Desikan-Killiany atlas for the DEFAULT HEAD MODEL
        %AND CORTEX. This will later be replaced by the code that calls for
        %the atlas computation.
        EEG = pop_multifit(EEG, [1:size(EEG.icaweights,1)] ,'threshold',100,'plotopt',{'normlen' 'on'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        if strcmp(atlasComput, 'Desikan-Killiany')
            %Calling for Desikan-Killiany dipole-to-area assignation.
            %This atlas only computes cortical areas!
            desikan_killiany_atlas
        elseif strcmp(atlasComput, 'Automated Anatomical Labeling')
            automated_anatomical_labeling
        else
            warning('dipole area asignation has NOT been updated after calling pop_multifit');
        end
        
        %EEG.dipfit.model.posXYZ will now contain the updated areas for
        %each dipole (according to set threshold)
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderDipoles);
        EEG = eeg_checkset( EEG );
        
        cyclesRun = cyclesRun + 1;
    end
    
end
close all;