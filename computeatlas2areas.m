FilesList = dir([pathName,'*.set']);

folderHM = strcat([uigetdir(cd,'Choose folder containing subjects head models for cortex or brainstem *** IN .MAT FORMAT ***'), slashSys]);
    FilesListHM = dir([folderHM,'*.mat']);

if ~exist('startPointScript', 'var') || strcmp(startPointScript,'Yes')
    
    atlasComput = questdlg('Which atlas will be used for dipole fitting?', ...
        'Choose atlas', ...
        'Desikan-Killiany','Automated Anatomical Labeling','Desikan-Killiany');
    if isempty(atlasComput)
        error('Must choose atlas');
    else
        fprintf('Will use the %s atlas', atlasComput);
    end
    
    brainComput = questdlg('Will you compute cortical or subcortical areas?', ...
        'Choose brain part', ...
        'Cortical','Subcortical','Both','Cortical');
    if strcmp(brainComput, 'Cortical')
        folderAtlas = strcat(folderAtlas, 'Cortex', slashSys);
        findAtlas = 2;
    elseif strcmp(brainComput, 'Subcortical')
        folderAtlas = strcat(folderAtlas, 'Brainstem', slashSys);
        findAtlas = 2;
    elseif strcmp(brainComput, 'Both')
        folderAtlas = strcat(folderAtlas, 'BrainstemAndCortex', slashSys);
        findAtlas = 4;
    end
    
end

cyclesRun = 0;
realFilenumDecimal = 1;

uiwait(msgbox('Starting script after closing this window...'));

for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
    
    %This avoids exporting anatomy files for same subjects twice
    %for each dataset. realFilenum will be used for calling the
    %head models, mri and channel locations.
    realFilenum = floor(realFilenumDecimal);
    
    %Extract the base file name in order to append extensions afterwards
    fileNameComplete = char(FilesList(Filenum).name);
    if contains(FilesList(Filenum).name,'Placebo')
        fileName = fileNameComplete(1:(conservedCharacters+3));
    else
        fileName = fileNameComplete(1:conservedCharacters);
    end
    
    newFileName = strcat(fileName, '_Atlas.set');
    
    ALLCOM = {};
    ALLEEG = [];
    CURRENTSET = 0;
    EEG = [];
    [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
    
    EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    if strcmp(atlasComput, 'Desikan-Killiany')
        fieldAtlas = 'areadk';
    elseif strcmp(atlasComput, 'Automated Anatomical Labeling')
        fieldAtlas = 'areaAAL';
    end
    
    if ~isfield(EEG.dipfit.model, fieldAtlas)
        
        if strcmp(atlasComput, 'Desikan-Killiany')
            %Calling for Desikan-Killiany dipole-to-area assignation.
            %This atlas only computes cortical areas!
            desikan_killiany_atlas
        elseif strcmp(atlasComput, 'Automated Anatomical Labeling')
            %call for AAL atlas. The structure of the head models of the
            %brainstem and the cortex exported from brainstorm have the
            %same structure: Atlas(2).Scouts(:).Vertices or .Label and are
            %appliable to cortex and to brainstorm area asignation of the
            %dipoles.
            autom_anat_labeling
        else
            warning('dipole area asignation has NOT been updated after calling pop_multifit');
        end
        
        %EEG.dipfit.model.posXYZ will now contain the updated areas for
        %each dipole (according to set threshold)
        EEG = eeg_checkset( EEG );
        EEG = pop_editset(EEG, 'setname', newFileName);
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderAtlas);
        EEG = eeg_checkset( EEG );
        
        cyclesRun = cyclesRun + 1;
        
    end
    
    close all;
end