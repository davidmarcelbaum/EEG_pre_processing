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
extractsws          = 0;    % Extract SWS periods of datasets
rejectchans         = 0;    % Reject non-wanted channels
eeglabfilter        = 0;    % Filtfilt processing. Parameters set when
                            % when function called in script
customfilter        = 1;    % Build and apply a custom zero-phase Fir 
                            % FiltFilt bandpass filter
medianfilter        = 0;    % Median filtering of noise artefacts of 
                            % low-frequency occurence
noisychans2zeros    = 0;    % Interpolation of noisy channels based on
                            % manually generated table with noisy chan info
noisyperiodreject   = 0;    % Rejection of noisy channels based on manually
                            % generated table with noisy period info
rereference         = 0;    % Re-reference channels to choosen reference.
                            % Reference is choosen when function is called
                            % in script
performica          = 0;    % Run ICA on datasets. This step takes a while
reject_IC           = 0;    % Extract information about artifact components
                            % and reject these
chan_interpol       = 0;    % Interpolate rejected channels (all 0)
downsample          = 0;    % Downsample datsets to user-defined sample fr
separate_trial_grps = 0;    % Separate trial series into groups. Parameters
                            % set when function is called in script.
                            
lastStep            = 'customfilter';
                            % Define last step to be done in this run
                            % {...
                            %   'extractsws', ...
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

% Modifiable declarations inside several files are also possible and tagged
%   |===USER INPUT===|
%
%   ...
%
%   |=END USER INPUT=|

pathData            = '/home/sleep/Documents/DAVID/Datasets/Ori_PlaceboNight/preProcessing/extrSWS/';
% String of file path to the mother stem folder containing the datasets

dataType            = '.set'; % {'.cdt', '.set', '.mff'}
% String of file extension of data to process

stimulation_seq     = 'switchedON_switchedOFF';
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

trials2rejFile   = '/home/sleep/Desktop/DAVID/GitHub/EEG_pre_processing/data_specific/GermanData/IC_rejection_info_CustomKaiserFilt_20200428.mat';
% Path to .mat file that contains information about trials to reject
% (explanations about organization of the file in f_sep_trial_groups
trials2rejVar    = 'comps2reject';
% Name of variable that holds the information about the trials to reject
% inside the .mat file
                            

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
    case 'filter'
        savePath = strcat(savePath, filesep, 'Filtered');
    case 'buildfiltfilt'
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
        case 'filter'
            str_savefile = strcat(str_savefile, '_Filt.set');
        case 'buildfiltfilt'
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
        run p_extract_sws.m        
        thisStep = 'extractsws';
        allSteps(end+1) = {thisStep};
    end
    
    
    if eeglabfilter == 1        
        run p_eeglabfilter.m        
        thisStep = 'filter';
        allSteps(end+1) = {thisStep};
    end
    
    
    if customfilter == 1
        run p_standalone/p_design_filter.m
        thisStep = 'buildfiltfilt';
        allSteps(end+1) = {thisStep};
    end
    
    
    if medianfilter == 1        
%         run p_medfilt.m
%         thisStep = 'medianfilter';
%         allSteps(end+1) = {thisStep};
        warning('MedFilt was set to be run but was skipped since commented!')
    end
    
    
    if noisychans2zeros == 1        
        run p_set_zerochans.m        
        thisStep = 'noisyperiodreject';
        allSteps(end+1) = {thisStep};
    end
    
    
    if noisyperiodreject == 1
        run p_noise_periods.m
        thisStep = 'noisyperiodreject';
        allSteps(end+1) = {thisStep};
    end
    
    
    if rejectchans == 1
        run p_chan_reject.m
        thisStep = 'rejectchans';
        allSteps(end+1) = {thisStep};
    end
    
    
    if rereference == 1
        run p_offlinereference
        thisStep = 'rereference';
        allSteps(end+1) = {thisStep};
    end
    
    
    if performica == 1
        [EEG, lst_changes{end+1,1}] = f_ica(EEG);
        thisStep = 'performica';
        allSteps(end+1) = {thisStep};
    end
    
    
    if reject_IC == 1
        [EEG, lst_changes{end+1,1}] = f_reject_ICs(...
            EEG, trials2rejFile, trials2rejVar);
        thisStep = 'reject_IC';
        allSteps(end+1) = {thisStep};
    end
    
    
    if chan_interpol == 1
        run p_interpolate
        thisStep = 'chan_interpol';
        allSteps(end+1) = {thisStep};
    end
    
    
    if separate_trial_grps == 1
        
        % Add the history of all called functions to EEG structure
        if ~isfield(EEG, 'lst_changes')
            EEG.lst_changes = lst_changes;
        else
            EEG.lst_changes(...
                numel(EEG.lst_changes) + 1 : ...
                numel(EEG.lst_changes) + numel(lst_changes)) = ...
                lst_changes;
        end
        
        [EEG_Cue, EEG_Sham, set_sequence] = ...
            f_sep_trial_groups(EEG, stimulation_seq, ...
            trials2rejFile, trials2rejVar);
        
        thisStep = 'separate_trial_grps';
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

        str_savefile_cue  = strcat(str_savefile, ...
            '_Cue_', set_sequence, '.set');
     
        [EEG_Cue] = pop_saveset( EEG_Cue, ...
            'filename', str_savefile_cue, ...
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
   
    
end

allSteps % all performed steps for end script verification
toc
