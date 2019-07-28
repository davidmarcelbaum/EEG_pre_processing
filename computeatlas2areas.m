FilesList = dir([pathName,'*.set']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Asking for head models and atlas choice %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('atlasComput', 'var') || ~exist('brainCompute', 'var') || ~exist('anatPath', 'var') || ~exist('startPointScript', 'var') || strcmp(startPointScript,'Yes')
%Skip questions if already answered and user chose to NOT reinitialize variables in master file.

    atlasComput = questdlg('Which atlas will be used for dipole fitting?', ...
        'Choose atlas', ...
        'Desikan-Killiany','Automated Anatomical Labeling','Desikan-Killiany');
    if isempty(atlasComput)
        error('Must choose atlas');
    else
        if strcmp(atlasComput, 'Desikan-Killiany')
            
            folderHM = strcat([uigetdir(cd,'Choose folder containing subjects head models for cortex or brainstem *** IN .MAT FORMAT ***'), slashSys]);
            FilesListHM = dir([folderHM,'*.mat']);
            
            brainCompute = 'cortex ONLY.';
            
            subjAnat = [1:numel(FilesList)]; %This is a dirty trick to circumvent the empty variable subjAnat
            %that is only defined by AAL atlas
            
        elseif strcmp(atlasComput, 'Automated Anatomical Labeling')
            
            %Setting up Head models. This part extracts vertices from various branstorm
            %files that contain either Subcortex or Cortex.
            anatPath = uigetdir(cd,'Locate the parent ("anat") folder of anatomies');
            anatList = dir(anatPath);
            [subjAnat,answerSubjAnat] = listdlg('PromptString','Select subject folders','SelectionMode','multiple','ListSize',[150,150],'ListString',{anatList.name});
            
            if ~istrue(size(FilesList,1) == 2*size(subjAnat,2))
                warning('FOUND MISMATCH BETWEEN NUMBER OF DATASETS AND NUMBER OF HEAD MODEL FILES!')
            end
            
            brainCompute = 'cortex AND subcortex.';
        end
        fprintf('*** Will use the %s atlas on %s ***', atlasComput, brainCompute);
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist(folderAtlas, 'dir') ~= 7
    mkdir (folderAtlas);
end

cyclesRun = 0;
realFilenumDecimal = 1;

uiwait(msgbox('Starting script after closing this window...'));

for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements
    
    %This avoids exporting anatomy files for same subjects twice
    %for each dataset. realFilenum will be used for calling the
    %head models, mri and channel locations.
    realFilenum = floor(realFilenumDecimal);
    
    Foldernum = subjAnat(realFilenum);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(atlasComput, 'Automated Anatomical Labeling')
        
        if exist([folderAtlas anatList(Foldernum).name '_head_model.mat']) ~= 2
            
            %Loading subject's anatomy files and combine them into one file to
            %compute atlas2area assignation. Brainstorm saves Brainstem and
            %Cerebrum separate from Cortex.
            SubjAnatPath = strcat(anatPath, slashSys, anatList(Foldernum).name, slashSys);
            
            subcortexFile = dir(fullfile(SubjAnatPath,'*MPRAGE_GRAPPA2_t1.svreg.label.nii.mat'));
            cortexFile = dir(fullfile(SubjAnatPath,'tess_cortex_pial_02.mat'));
            
            getSubcortexFile = load(strcat(subcortexFile.folder, slashSys, subcortexFile.name));
            getCortexFile = load(strcat(cortexFile.folder, slashSys, cortexFile.name));
            
            hm.Vertices = [getCortexFile.Vertices; getSubcortexFile.Vertices];
            %hm.Atlas = [getCortexFile.Atlas(4).Scouts, getSubcortexFile.Atlas(2).Scouts];
            hm.Atlas = [getCortexFile.Atlas(4).Scouts];
            
            if ~size(hm.Vertices,1) == size(getSubcortexFile.Vertices,1) + size(getCortexFile.Vertices,1)
                error('Something went wrong during Vertex concatenation')
            end
            
            save([folderAtlas anatList(Foldernum).name '_head_model.mat'],'hm')
            
        else
            load([folderAtlas anatList(Foldernum).name '_head_model.mat'],'hm')
        end
        
    elseif strcmp(atlasComput, 'Desikan-Killiany')
        
        % loading hm file
        hm = load([folderHM, FilesListHM(realFilenum).name]);
        
    end
    
%     if strcmp(atlasComput, 'Desikan-Killiany')
%         
%         cortexFile = dir(fullfile(SubjAnatPath,'tess_cortex_pial_02.mat'));
%         
%         getCortexFile = load(strcat(cortexFile.folder, slashSys, cortexFile.name));
%         
%         hm.Vertices = [getCortexFile.Vertices];
%         
%     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
    
    if exist([folderAtlas, newFileName], 'file')
       EEG = pop_loadset('filename',newFileName,'filepath',folderAtlas); 
    else
       EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);
    end
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    if ~isfield(EEG.dipfit, 'model')
        error(strcat('Dataset', fileNameComplete, ' Does not contain dipole computation'));
    end
    
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
    
    realFilenumDecimal = realFilenumDecimal + 0.5;
    
    close all;
end