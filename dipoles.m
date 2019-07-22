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
    
    %Search for Head Model (HM)
    [stdHeadModel, stdHeadModelPath] = uigetfile('*.mat','Look for standard head model',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'standard_vol.mat'));
    %folderHM = strcat([uigetdir(cd,'Choose folder containing subjects head models *** IN .MAT FORMAT ***'), slashSys]);
    %FilesListHM = dir([folderHM,'*.mat']);
    
    %Search for standard electrode for 10-20 system
    % Exchanged for "chanLocFileELC" [stdElectrodes, stdElectrodesPath] = uigetfile('*.elc','Look for channel locations file',strcat(eeglabFolder, 'plugins', slashSys, 'dipfit', slashSys, 'standard_BEM', slashSys, 'elec', slashSys, 'standard_1020.elc'));
    
    %Search for MRI anatomy folder of subjects
    subjAnatFolder = [uigetdir(folderHM,'Choose folder containing subjects anatomy *** IN .HDR / .IMG FORMAT ***'), slashSys];
    subjAnat = dir([subjAnatFolder, '*.hdr']);
    
    %Search for channel locations folder of subjects
    chanLocFolder = [uigetdir(subjAnatFolder,'Choose folder containing subjects channel locations *** IN BOTH .ELC AND .XYZ FORMAT ***'), slashSys];
    chanLocFilesXYZ = dir([chanLocFolder, '*.xyz']);
    chanLocFilesELC = dir([chanLocFolder, '*.elc']);
    
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
        EEG = pop_multifit(EEG, [1:size(EEG.icaweights,1)] ,'threshold',100,'plotopt',{'normlen' 'on'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% This is extracted from the eeg_compatlas.m of the %%%
        %%%% dipfit plugin                                     %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %function EEG = eeg_compatlas(EEG, varargin)
        
        %if nargin < 1
        %    help eeg_compatlas;
        %    return
        %end
        
        if ~isfield(EEG, 'dipfit') || isempty(EEG.dipfit) || ~isfield(EEG.dipfit, 'model') || isempty(EEG.dipfit.model)
            error('You must run dipole localization first');
        end
        
        % decode options
        % --------------
        %g = finputcheck(varargin, ...
        %    { 'atlas'      'string'    {'dk' }     'dk';
        %    'components' 'integer'   []          [1:size(EEG.icaweights,1)] });
        %if isstr(g), error(g); end;
        
        % loading hm file
        hm = load([folderHM, FilesListHM(realFilenum).name]);
        
        if isdeployed
            stdHM = load('-mat', fullfile( eeglabFolder, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
            if ~exist(meshfile)
                error(sprintf('headplot(): deployed mesh file "%s" not found\n','head_modelColin27_5003_Standard-10-5-Cap339.mat'));
            end
        else
            p  = fileparts(which('eeglab.m'));
            stdHM = load('-mat', fullfile( p, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
        end
        
        
        % coord transform to the HM file space
        if strcmpi(EEG.dipfit.coordformat, 'MNI')
            tf = traditionaldipfit([0.0000000000 -26.6046230000 -46.0000000000 0.1234625600 0.0000000000 -1.5707963000 1000.0000000000 1000.0000000000 1000.0000000000]);
        elseif strcmpi(EEG.dipfit.coordformat, 'spherical')
            tf = traditionaldipfit([-5.658258      1.039259     -42.80596   -0.00981033    0.03362692   0.004391199      860.8199      926.6112       858.162]);
        else
            error('Unknown coordinate format')
        end
        tfinv = pinv(tf); % the transformation is from HM to MNI (we need to invert it)
        
        % scan dipoles
        fprintf('Looking up brain area in the Desikan-Killiany Atlas\n');
        for iComp = [1:size(EEG.icaweights,1)] %Default is: iComp = g.components(:)'
            if size(EEG.dipfit.model(iComp).posxyz,1) == 1
                atlascoord = tfinv * [EEG.dipfit.model(iComp).posxyz 1]';
                
                % find close location in Atlas
                distance = sqrt(sum((hm.Vertices-repmat(atlascoord(1:3)', [size(hm.Vertices,1) 1])).^2,2));
                % distance = sqrt(sum((hm.VertNormals-repmat(atlascoord(1:3)', [size(hm.VertNormals,1) 1])).^2,2));

                
                % compute distance to each brain area
                [~,selectedPt] = min( distance );
                area = stdHM.atlas.colorTable(selectedPt);
                if area > 0
                    EEG.dipfit.model(iComp).areadk = stdHM.atlas.label{area};
                else
                    EEG.dipfit.model(iComp).areadk = 'no area';
                end
                
                fprintf('Component %d: area %s\n', iComp, EEG.dipfit.model(iComp).areadk);
            else
                if ~isempty(EEG.dipfit.model(iComp).posxyz)
                    fprintf('Component %d: cannot find brain area for bilateral dipoles\n', iComp);
                else
                    fprintf('Component %d: no location (RV too high)\n', iComp);
                end
            end
        end
        %end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',folderDipoles);
        EEG = eeg_checkset( EEG );
        
        cyclesRun = cyclesRun + 1;
    end
    
end
close all;