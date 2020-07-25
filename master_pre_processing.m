% This script performs several pre_processing steps on EEG recordings. The
% code makes heavy use of EEGLAB 2019.1 and all credits go to the
% developpers of the EEGLAB toolbox.
% This script can handle .mff, .set and [.............] datasets
% Order of pre-processing steps is to be changed in section 2 "Perform
% pre-processing steps" and does not require any further changes.



%% Terms and conditions
%  ====================

% Available under the terms of the Berkeley Software Distribution licence:
% Copyright (c) 2020, Laboratory for Brain-Machine Interfaces and
% Neuromodulation, Pontificia Universidad Católica de Chile, hereafter 
% referred to as the "Organization".
% All rights reserved.
% 
% Redistribution and use in source and binary forms are permitted
% provided that the above copyright notice and this paragraph are
% duplicated in all such forms and that any documentation,
% advertising materials, and other materials related to such
% distribution and use acknowledge that the software was developed
% by the Organization. The name of the
% Organization may not be used to endorse or promote products derived
% from this software without specific prior written permission.
% THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
% IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.



%% Important user-defined variables
%  ================================

% Define all steps to be performed: 0 for false and 1 for true
extractsws          = 1;    % Extract SWS periods of datasets
defdetrend          = 1;    % Detrend the dataset (quadtratic, linear,
                            % continuous, discontinuous)
eeglabfilter        = 0;    % Filtfilt processing. Parameters set when
                            % when function called in script
customfilter        = 0;    % Build and apply a custom zero-phase Fir 
                            % FiltFilt bandpass filter
medianfilter        = 0;    % Median filtering of noise artefacts of 
                            % low-frequency occurence
noisychans2zeros    = 1;    % Interpolation of noisy channels based on
                            % manually generated table with noisy chan info
noisyperiodreject   = 1;    % Rejection of noisy channels based on manually
                            % generated table with noisy period info
rejectchans         = 1;    % Reject non-wanted channels
rereference         = 1;    % Re-reference channels to choosen reference.
                            % Reference is choosen when function is called
                            % in script
performica          = 0;    % Run ICA on datasets. This step takes a while
reject_IC           = 0;    % Extract information about artifact components
                            % and reject these
chan_interpol       = 1;    % Interpolate rejected channels (all 0)
downsample          = 0;    % Downsample datsets to user-defined sample fr
separate_trial_grps = 1;    % Separate trial series into groups. Parameters
                            % set when function is called in script.
                            
lastStep            = 'separate_trial_grps';
                            % Define last step to be done in this run
                            % {...
                            %   'extractsws', ...
                            %   'defdetrend', ...
                            %   'rejectchans', ...
                            %   'filter', ...
                            %   'customfilter', ...
                            %   'medianfilter', ...
                            %   'noisychans2zeros', ...
                            %   'noisyperiodreject', ...
                            %   'performica', ...
                            %   'reject_IC', ...
                            %   'separate_trial_grps', ...
                            %   'rereference', ...
                            %   'chan_interpol', ...
                            %   'downsample'}

pathData            = 'D:\germanStudyData\datasetsSETS\Ori_TaskassoNight\';
% String of file path to the mother stem folder containing the datasets

dataType            = '.mff'; % {'.cdt', '.set', '.mff'}
% String of file extension of data to process

stimulation_seq     = 'switchedON_switchedOFF';
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

baselineCorr = []; % [-7000 0] Array of min and max (ms) for baseline
% Baseline correction when epochs are extracted from dataset in
% f_sep_trial_groups. Leave empty if no correction is desired.


trials2rejFile   = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\IC_rejection_info_CustomKaiserFilt_20200721.mat';
% Path to .mat file that contains information about trials to reject
% (explanations about organization of the file in f_sep_trial_groups

trials2rejVar    = 'comps2reject';
% Name of variable that holds the information about the trials to reject
% inside the .mat file

% Modifiable declarations inside several files are also possible and tagged
%   |===USER INPUT===|
%
%   ...
%
%   |=END USER INPUT=|


%                         +-------------------+
% ------------------------| END OF USER INPUT |----------------------------
%                         +-------------------+



%% Setting up user land
%  ====================
% -------------------------------------------------------------------------
% Define variables to be shared across workspaces
global str_base


% -------------------------------------------------------------------------
% Here we set up the list of recording files that will be processed in the 
% script

ls_files        = dir(pathData);

% "dir" is also listing the command to browse current folder (".") and step
% out of folder (".."), so we reject these here
rej_dot         = find(strcmp({ls_files.name}, '.'));
rej_doubledot   = find(strcmp({ls_files.name}, '..'));
rej             = [rej_dot rej_doubledot];

ls_files(rej)   = [];

% Reject files that do not correspond to the user-defined format
rej_nonformat   = find(~contains({ls_files.name}, dataType));

ls_files(rej_nonformat) = [];

num_files       = size(ls_files, 1);


% -------------------------------------------------------------------------
% Stop right here when no files have been found

if isempty(ls_files) || num_files == 0
    
    error('No datasets to process. Verify variables "pathData" and "dataType".')

end


% -------------------------------------------------------------------------
% Here, we locate EEGLAB toolbox since the path might differ between
% systems. This will then add the functions the script needs to MATLAB path

locateEeglab = which('eeglab.m');
[folderEEGLAB, ~, ~] = fileparts(locateEeglab);
addpath(genpath(folderEEGLAB))


% -------------------------------------------------------------------------
% Correcting potential error sources and clearing unnecessary variables

if strcmp(pathData(end), filesep)
    pathData(end)       = [];
end


clearvars rej rej_dot rej_doubledot rej_nonformat globalvars


% -------------------------------------------------------------------------
% Create folder structures for saving the datasets after processing

if contains(pathData, 'preProcessing')
    savePath = erase(pathData, extractAfter(pathData, 'preProcessing'));
else
    savePath = strcat(pathData, filesep, 'preProcessing');
end


% Adapt savePath to last step and add appendix to dataset name
% accordingly: This will allow to collect databases easier
% just by running "dir" on pathData.

switch lastStep
    
    case 'extractsws'
        savePath = strcat(savePath, filesep, 'extrSWS');
    case 'rejectchans'
        savePath = strcat(savePath, filesep, 'DataChans');
    case 'defdetrend'
        savePath = strcat(savePath, filesep, 'Detrend');
    case 'filter'
        savePath = strcat(savePath, filesep, 'Filtered');
    case 'customfilter'
        savePath = strcat(savePath, filesep, 'CustomFiltered');
    case 'medianfilter'
        savePath = strcat(savePath, filesep, 'MedianFiltered');
    case 'noisychans2zeros'
        savePath = strcat(savePath, filesep, 'NoisyChans');
    case 'noisyperiodreject'
        savePath = strcat(savePath, filesep, 'NoisyPeriods');
    case 'performica'
        savePath = strcat(savePath, filesep, 'ICAweights');
    case 'rereference'
        savePath = strcat(savePath, filesep, 'ReRef');
    case 'reject_IC'
        savePath = strcat(savePath, filesep, 'ICAclean');
    case 'separate_trial_grps'
        savePath = strcat(savePath, filesep, 'TrialGroups');
    case 'chan_interpol'
        savePath = strcat(savePath, filesep, 'ChanInterpol');
end


if ~exist(savePath, 'dir')
    
    mkdir(savePath);
    
end

% End of user land setup
% ======================



%% The core of the script
%  ======================
% Every script seems rough on the outside, but has a soft core, so treat it nicely.

tic;
for s_file = 1 : num_files
        
    fprintf('\n<!> Running %s (%d/%d)...\n', ...
        ls_files(s_file).name, s_file, num_files) % Report stage
    
    
    %% 0. Define subject
    %  =================
    % ---------------------------------------------------------------------
    % Here, we extract the string of the subject number and the recording
    % session
    
    % |===USER INPUT===|
    str_subj            = extractAfter(ls_files(s_file).name, 'RC_');
    str_subj            = extractBefore(str_subj, '_');
    
    str_session         = str_subj(3); % Number of session
    str_subjnum     	= str_subj(1:2); % Number of subject
    % |=END USER INPUT=|
    
    
    if strcmp(dataType, '.set')
        % Extract the last step performed on the datset
        str_savefile    = extractBefore(ls_files(s_file).name, dataType);
        str_parts       = strsplit(str_savefile, '_');
        str_savefile    = extractBefore(str_savefile, ...
            strcat('_', str_parts(end)));
    else
        % Else, just get the file name without extension since no step
        % performed yet
        str_savefile    = extractBefore(ls_files(s_file).name, dataType);
                            % The str_savefile will be adapted according to
                            % the last step performed later.
    end
    
    str_base = str_savefile;
    
    
    % Appendix to dataset name accordingly to last step performed:
    % This will allow to collect databases easier just by running "dir" 
    % on pathData.
    switch lastStep
        
        case 'extractsws'
            str_savefile = strcat(str_savefile, '_SWS.set');
        case 'rejectchans'
            str_savefile = strcat(str_savefile, '_ChanReject.set');
        case 'defdetrend'
            str_savefile = strcat(str_savefile, '_Detrend.set');
        case 'filter'
            str_savefile = strcat(str_savefile, '_Filt.set');
        case 'customfilter'
            str_savefile = strcat(str_savefile, '_CustomFilt.set');
        case 'medianfilter'
            str_savefile = strcat(str_savefile, '_MedianFilt.set');
        case 'noisychans2zeros'
            str_savefile = strcat(str_savefile, '_NoisyChans.set');
        case 'noisyperiodreject'
            str_savefile = strcat(str_savefile, '_NoisyPeriods.set');
        case 'performica'
            str_savefile = strcat(str_savefile, '_ICAweights.set');
        case 'rereference'
            str_savefile = strcat(str_savefile, '_ReRef.set');
        case 'reject_IC'
            str_savefile = strcat(str_savefile, '_ICAclean');
        case 'separate_trial_grps'
            % Will be adapted by function;
        case 'chan_interpol'
            str_savefile = strcat(str_savefile, '_ChanInterp');
            
    end
    
    
    % ---------------------------------------------------------------------
    % This is useful in order to store the history of EEGLAB functions 
    % called during file processing
    lst_changes         = {};
       
    
    % ---------------------------------------------------------------------
    % Break out of loop if the subject dataset has already been processed
    if exist(strcat(savePath, filesep, str_savefile), 'file')
        fprintf('... skipped because already exists\n\n')
        continue
    end
    % End of subject definition
    % =========================
    
    
    
    %% 1. Import datasets into EEGLAB-like structures
    %  ==============================================
    
    [EEG, lst_changes{end+1,1}] = f_load_data(...
        ls_files(s_file).name, pathData, dataType);
    
    % End of import
    % =============
    
    
    %% 2. Perform pre-processing steps
    %  ===============================
    
    % THESE STEPS CAN BE CHANGED IN ORDER WITHOUT ANY FURTHER CHANGES
    % NEEDED IN THE SCRIPT
    
    allSteps = {};
    
    if extractsws == 1
        thisStep = 'extractsws'
        run p_extract_sws.m        
        allSteps(end+1) = {thisStep};
    end
    
    
    if defdetrend == 1
        thisStep = 'defdetrend'
        [EEG.data, lst_changes{end+1,1}] = f_detrend(EEG.data, ...
            [], false, {});
        allSteps(end+1) = {thisStep};
    end
    
    
    if eeglabfilter == 1
        thisStep = 'filter';
        run p_eeglabfilter.m
        allSteps(end+1) = {thisStep};
    end
    
    
    if customfilter == 1
        thisStep = 'customfilter'
        run p_standalone/p_design_filter.m
        allSteps(end+1) = {thisStep};
    end
    
    
    if medianfilter == 1     
%         thisStep = 'medianfilter'
%         run p_medfilt.m
%         allSteps(end+1) = {thisStep};
        warning('MedFilt was set to be run but was skipped since commented!')
    end
    
    
    if noisychans2zeros == 1
        thisStep = 'noisychans2zeros'
        run p_set_zerochans.m        
        allSteps(end+1) = {thisStep};
    end
    
    
    if noisyperiodreject == 1
        thisStep = 'noisyperiodreject'
        run p_noise_periods.m
        allSteps(end+1) = {thisStep};
    end
    
    
    if rejectchans == 1
        thisStep = 'rejectchans';
        run p_chan_reject.m
        allSteps(end+1) = {thisStep};
    end
    
    
    if rereference == 1
        thisStep = 'rereference'
        run p_offlinereference
        allSteps(end+1) = {thisStep};
    end
    
    
    if performica == 1
        thisStep = 'performica'
        [EEG, lst_changes{end+1,1}] = f_ica(EEG);
        allSteps(end+1) = {thisStep};
    end
    
    
    if reject_IC == 1
        thisStep = 'reject_IC'
        [EEG, lst_changes{end+1,1}] = f_reject_ICs(...
            EEG, trials2rejFile, trials2rejVar);
        allSteps(end+1) = {thisStep};
    end
    
    
    if chan_interpol == 1
        thisStep = 'chan_interpol'
        run p_interpolate
        allSteps(end+1) = {thisStep};
    end
    
    
    if separate_trial_grps == 1
        
        thisStep = 'separate_trial_grps'
        
        % Add the history of all called functions to EEG structure
        if ~isfield(EEG, 'lst_changes')
            EEG.lst_changes = lst_changes;
        else
            EEG.lst_changes(...
                numel(EEG.lst_changes) + 1 : ...
                numel(EEG.lst_changes) + numel(lst_changes)) = ...
                lst_changes;
        end
        
        [EEG_Odor, EEG_Sham, set_sequence] = ...
            f_sep_trial_groups(EEG, stimulation_seq, ...
            trials2rejFile, trials2rejVar, baselineCorr);
        
        allSteps(end+1) = {thisStep};
        
    end
    
    
    if ~strcmp(lastStep, thisStep)
        warning('Filename and filepath to save in are not corresponding to defined last step!')
    end    
    % End of pre-processing
    % =====================
    
    
    
    %% 3. Save dataset
    %  ===============
    
    if strcmp(thisStep, 'separate_trial_grps')
        
        str_savefile_sham  = strcat(str_savefile, ...
            '_Sham_', set_sequence, '.set');

        str_savefile_odor  = strcat(str_savefile, ...
            '_Odor_', set_sequence, '.set');
     
        [EEG_Odor] = pop_saveset( EEG_Odor, ...
            'filename', str_savefile_odor, ...
            'filepath', savePath);
        
        [EEG_Sham] = pop_saveset( EEG_Sham, ...
            'filename', str_savefile_sham, ...
            'filepath', savePath);
        
    else
        
        % Add the history of all called functions to EEG structure
        if ~isfield(EEG, 'lst_changes')
            EEG.lst_changes = lst_changes;
        else
            EEG.lst_changes(...
                numel(EEG.lst_changes) + 1 : ...
                numel(EEG.lst_changes) + numel(lst_changes)) = ...
                lst_changes;
        end
        
        [EEG] = pop_saveset( EEG, ...
            'filename', str_savefile, ...
            'filepath', savePath);
        
    end
    
    clearvars EEG_Odor EEG_Sham
   
    
end

allSteps % all performed steps for end script verification
toc
