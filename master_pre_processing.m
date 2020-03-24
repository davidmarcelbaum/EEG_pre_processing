% This script performs the following steps on EEG datasets:
% 1.	Import datasets into EEGLAB
% 2.	Extract SWS (2, 3 and 4)
% 3.	Reject non-wanted channels (such as M1, M2, HEOG, VEOG, Triggers, Ref)
% 5.	Filtfilt 0.1 45
% 6.	Reduce spike bursts noise by additional filtering
% 7.	Automatic and eye-based rejection of noisy channels
%       a.	Set these to zeros(channel, columns) and interpolate them
% 8.	Re-ref mean of all excluding 0 channels
% 9.	Rej noisy periods
% 10.	ICA excluding chans of zeros (step 6)
% 11.	Component rej
% 12.   Interpolate channels of zeros (from step 7) with artefact-cleaned
%       channels
% 13.	Epoch into trials
% 14.	Rej epochs of noise and of artefactual components (ICA weights)
% 15.	Separate trigger groups into distinct datasets
% 16.   Downsample to 100Hz

% This script can handle .mff, .set and [.............] datasets



%% Terms and conditions
%  ====================

% Avilable under the terms of the Berkeley Software Distribution licence:
% Copyright (c) 2020, Laboratory for Brain-Machine Interfaces and
% Neuromodulation, Pontificia Universidad Católica de Chile,
% hereafter referred to as the "Organization".
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

% Modifiable declarations inside several files are also possible and tagged
%   |===USER INPUT===|
%
%   ...
%
%   |=END USER INPUT=|

% set(0, 'defaultFigureRenderer', 'painters')
% set(0, 'defaultFigureRenderer', 'zbuffer')
% One of both appearently can accelerate eegplot function 

pathData            = '/home/sleep/Desktop/DAVID/Datasets/Ori/preProcessing/NoisyChans';
% String of file path to the mother stem folder containing the datasets

dataType            = '.set'; % {'.cdt', '.set', '.mff'}
% String of file extension of data to process

% Choose what steps will be performed
% MANUAL STEPS OCCUR AFTER:
% - medianfilter    :   Automatic and eye-based rejection of noisy channels
% - rereference     :   Rej noisy periods
% - runica          :   Component rej
% - epoching        :   Trial-based component rejection
% AND SHOULD THEREFORE BE THE LAST 1 SET INSIDE RUN

% Define all steps to be performed: 0 for false and 1 for true
extractsws          = 0;    % Extract SWS periods of datasets
rejectchans         = 0;    % Reject non-wanted channels
filter              = 0;    % Filtfilt processing. Parameters set when
                            % when function called in script
medianfilter        = 0;    % Median filtering of noise artefacts of 
                            % low-frequency occurence
noisychans2zeros    = 0;    % Interpolation of noisy channels based on
                            % manually generated table with noisy chan info
noisyperiodreject   = 1;    % Rejection of noisy channels based on manually
                            % generated table with noisy period info
performica          = 0;    % Run ICA on datasets. This step takes a while
rereference         = 0;    % Re-reference channels to choosen reference.
                            % Reference is choosen when function is called
                            % in script
epoching            = 0;    % Slice datasets according to trigger edges.
                            % Parameters set when function is called in
                            % script
separategroups      = 0;    % Separate trial series into groups. Parameters
                            % set when function is called in script.
                            

%                         +-------------------+
% ------------------------| END OF USER INPUT |----------------------------
%                         +-------------------+



%% Setting up user land
%  ====================
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

if ~isempty(locateEeglab)
    
    [folderEEGLAB, ~, ~] = fileparts(locateEeglab);
    
    strcat(folderEEGLAB, filesep, 'functions', filesep, 'adminfunc');
    strcat(folderEEGLAB, filesep, 'functions', filesep, 'popfunc');
    
else
    
    error('EEGLAB not found')
    
end


% -------------------------------------------------------------------------
% It is probably good to initialize EEGLAB variables once and also allows
% to reinitialize the EEG structure which holds heavy variables and is
% likely to make MATLAB throw out of memory errors.

eeglab;
close all;


% -------------------------------------------------------------------------
% Correcting potential error sources and clearing unnecessary variables

if strcmp(pathData(end), filesep)
    pathData(end)       = [];
end


clearvars rej rej_dot rej_doubledot rej_nonformat STUDY PLUGINLIST ...
    CURRENTSTUDY CURRENTSET ALLEEG ALLCOM eeglabUpdater LASTCOM globalvars


% -------------------------------------------------------------------------
% Create folder structures for saving the datasets after processing

if contains(pathData, 'preProcessing')
    savePath = erase(pathData, extractAfter(pathData, 'preProcessing'));
else
    savePath = strcat(pathData, filesep, 'preProcessing');
end


% Adapt savePath to last step: This will allow to collect databases easier 
% just by running "dir" on pathData.

allSteps = [extractsws, rejectchans, filter, medianfilter, ...
    noisychans2zeros, noisyperiodreject, performica, rereference, ...
    epoching, separategroups];

stepsPerformed = find(allSteps == 1);
lastStep = stepsPerformed(end);

switch lastStep
    
    case 1 % Extract SWS
        
        savePath = strcat(savePath, filesep, 'extrSWS');
        
    case 2 % Reject channels
        
        savePath = strcat(savePath, filesep, 'DataChans');
        
    case 3 % Filter
        
        savePath = strcat(savePath, filesep, 'Filtered');
        
    case 4 % Median Filter for spike rejection
        
        savePath = strcat(savePath, filesep, 'MedianFiltered');
        
    case 5 % Noisy channels to be set to zeros
        
        savePath = strcat(savePath, filesep, 'NoisyChans');
        
    case 6 % Reject noisy periods
        
        savePath = strcat(savePath, filesep, 'NoisyPeriods');
        
    case 7 % ICA running
        
        savePath = strcat(savePath, filesep, 'ICAweights');
        
    case 8 % Re-reference channel data
        
        savePath = strcat(savePath, filesep, 'offlineRef');
        
    case 9 % Epoching of datasets based on events
        
        savePath = strcat(savePath, filesep, 'Epoched');
        
    case 10 % Separation of event types
        
        % Here, the script from Andrea applies
        
end


if ~exist(savePath, 'dir')
    
    mkdir(savePath);
    
end
% End of user land setup
% ======================



%% The core of the script
%  ======================
% Every script seems rough on the outside, but has a soft core, so treat it nicely.

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
    % |=END USER INPUT=|
    
    
    str_session         = str_subj(3); % Number of session
    str_subjnum     	= str_subj(1:2); % Number of subject
    
    
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
    
    
    % ---------------------------------------------------------------------
    % This is useful in order to store the history of EEGLAB functions 
    % called during file processing

    lst_changes         = {};
   
    
    % ---------------------------------------------------------------------
    % Add an appendix to the data base that defines the state of 
    % pre-processing when saved
    
    str_subject_short = str_savefile;
    
    
    switch lastStep
        
        case 1 % Extract SWS
            
            str_savefile = strcat(str_savefile, '_SWS.set');
            
        case 2 % Reject channels
            
            str_savefile = strcat(str_savefile, '_ChanReject.set');
            
        case 3 % Filter
            
            str_savefile = strcat(str_savefile, '_Filt.set');
            
        case 4 % Median Filter for spike rejection
            
            str_savefile = strcat(str_savefile, '_MedianFilt.set');
            
        case 5 % Noisy channels to be set to zeros
            
            str_savefile = strcat(str_savefile, '_NoisyChans.set');
            
        case 6 % Re-reference channel data
            
            str_savefile = strcat(str_savefile, '_Re-reference.set');
            
        case 7 % ICA running
            
            str_savefile = strcat(str_savefile, '_ICAweights.set');
            
        case 8 % Epoching of datasets based on events
            
            str_savefile = strcat(str_savefile, '_Epoched.set');
            
        case 9 % Separation of event types
            
            % Here, the script from Andrea applies
            
    end
       
    
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
    
    if strcmp(dataType,'.set')
        
        
        [EEG, lst_changes{end+1,1}] = ...
            pop_loadset('filename', ls_files(s_file).name, ...
            'filepath', pathData);
        
        
    elseif strcmp(dataType,'.mff')
        
        
        % mff folders contain various files
        [EEG, lst_changes{end+1,1}] = ...
            pop_mffimport([pathData, filesep, ls_files(s_file).name], ...
            {'classid' 'code' 'description' 'label' 'mffkey_cidx' ...
            'mffkey_gidx' 'mffkeys' 'mffkeysbackup' 'relativebegintime' ...
            'sourcedevice'});
        
        
    elseif strcmp(dataType,'.cdt')
        
        
        [EEG, lst_changes{end+1,1}] = ...
            loadcurry([pathData, filesep, ls_files(s_file).name], ...
            'CurryLocations', 'False');
        
        
    end
    % End of import
    % =============
    
    
    %% 2. Perform pre-processing steps
    %  ===============================
    
    if extractsws == 1
        
        run p_extract_sws.m
       
    end
    
    
    if rejectchans == 1
        
        run p_chan_reject.m
                
    end
    
    
    if filter == 1
        
        run p_filter.m
        
    end
    
    
    if medianfilter == 1
        
        run p_medfilt.m
        
    end
    
    
    if noisychans2zeros == 1
        
        run p_set_zerochans.m        
        
    end
    
    
    if noisyperiodreject == 1
        
        run p_noise_periods.m
        
    end
    
    
    if performica == 1
        
        run p_ica.m
        
    end
    
    
    if rereference == 1
        
        run p_offlinereference
        
    end
    % End of pre-processing
    % =====================
    
    
    
    %% 3. Save dataset
    %  ===============
    
    % Add the history of all called functions to EEG structure
    if ~isfield(EEG, 'lst_changes')    
        EEG.lst_changes = lst_changes;
    else
        EEG.lst_changes(...
            numel(EEG.lst_changes) + 1 : ...
            numel(EEG.lst_changes) + numel(lst_changes)) = ...
            lst_changes;
    end
    
    
    [EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
        'filename', str_savefile, ...
        'filepath', savePath);
    
    
    % Optional, but this way, we make sure data does not get mixed between 
    % subjects.
    clear EEG
    
   
    
end
