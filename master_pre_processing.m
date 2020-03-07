% This script performs the following steps on EEG datasets:
% 1.	Import datasets into EEGLAB
% 2.	Extract SWS (2, 3 and 4)
% 3.	Reject non-wanted channels (such as M1, M2, HEOG, VEOG, Triggers, Ref)
% 5.	Filtfilt 0.1 45
% 6.	Reduce spike bursts noise by additional filtering
% 7.	Automatic and eye-based rejection of noisy channels
% a.	Set these to zeros(channel, columns)
% 8.	Re-ref mean of all excluding 0 channels
% 9.	Rej noisy periods
% 10.	ICA excluding chans of zeros (step 6)
% 11.	Component rej
% 12.	Epoch into trials
% 13.	Rej epochs of noise and of artefactual components (ICA weights)
% 14.	Separate trigger groups into distinct datasets

% This script can handle .mff, .set and [.............] datasets



%% Important user-defined variables
%  ================================

% Modifiable declarations inside several files are also possible and tagged
%   |===USER INPUT===|
%
%   ...
%
%          |=END USER INPUT=|

pathData            = '/home/sleep/Documents/DAVID/Datasets/Ori/';
% String of file path to the mother stem folder containing the datasets

dataType            = '.mff'; % {'.cdt', '.set', '.mff'}
% String of file extension of data to process

pathSleepScore      = '/home/sleep/Documents/DAVID/Datasets/Hypnograms/';
% String of file path to the mother stem folder containing the files of
% sleep scoring of the subjects. LEAVE EMPTY ("''") IF DOES NOT APPLY

chunk_scoring       = 30; % scalar (s)
% What was the scoring interval (in seconds)

sleepStages         = [2, 3, 4]; % [scalars]
% Define the sleep stages of interest to use if scleep scoring files will
% be sideloaded

chans2Rej           = {...
    'E57', ...
    'E100', ...
    'E43', ...
    'E120', ...
    'E25', ...
    'E126', ...
    'E127', ...
    'E21', ...
    'E8', ...
    'E14', ...
    'E129', ...
    'E49', ...
    'E48', ...
    'E17', ...
    'E128', ...
    'E32', ...
    'E1', ...
    'E125', ...
    'E119', ...
    'E113', ...
    };
% Cell array of strings that specifies the channels to reject from datasets
% These will be discarded from dataset entirely from very beginning and 
% will not be accessible in subsequent steps.

filt_highpass       = 0.1;
filt_lowpass        = 45;
% Frequencies to use as boundaries for filtering

lst_changes         = {};
% This is useful in order to store the history of EEGLAB functions called
% called duringfile processing

% import data is done in any case
extractsws          = 1;    % Extract SWS periods of datasets
rejectchans         = 1;    % Reject non-wanted channels
filter              = 1;    % Filtfilt processing. Parameters set when
                            % when function called in script
medianfilter        = 1;    % Median filtering of noise artefacts of 
                            % low-frequency occurence
detectnoisychans    = 0;    % Automatic detection of noisy channels
                            % Parameters set when function is called in
                            % script
rereference         = 0;    % Re-reference channels to choosen reference.
                            % Reference is choosen when function is called
                            % in script
runica              = 0;    % Run ICA on datasets. This step takes a while
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
% Here we set up the list of sleep scoring files that will be processed in
% the script

ls_score        = dir(pathSleepScore);

% "dir" is also listing the command to browse current folder (".") and step
% out of folder (".."), so we reject these here
rej_dot         = find(strcmp({ls_score.name}, '.'));
rej_doubledot   = find(strcmp({ls_score.name}, '..'));
rej             = [rej_dot rej_doubledot];

ls_score(rej)   = [];


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

if strcmp(pathSleepScore(end), filesep)
    pathSleepScore(end) = [];
end

clearvars rej rej_dot rej_doubledot rej_nonformat STUDY PLUGINLIST ...
    CURRENTSTUDY CURRENTSET ALLEEG ALLCOM eeglabUpdater LASTCOM globalvars


% -------------------------------------------------------------------------
% Create file structures for saving the datasets after processing

% All data outputs will be saved in this folder
savePath = strcat(pathData, filesep, 'preProcessing');

if ~exist(savePath, 'dir')
    
    mkdir(savePath);
        
end
% End of user land setup
% ======================



%% The core of the script. Every script seems rough on the outside, but has
%  a soft core, so treat it nicely.
%  ========================================================================

for s_file = 1 : num_files
    
    
    fprintf('<!> Running %s ...\n', ls_files(s_file).name) % Report stage
    
    
    
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
    
    str_savefile        = extractBefore(ls_files(s_file).name, dataType);
    str_savefile        = strcat(str_savefile, '_preProcessing.set');
                          % The appendix "preProcessing" will be replaced
                          % according to the last step performed later.
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
    
    
    
    %% Execute pre-processing steps
    %  ============================
    
    % ---------------------------------------------------------------------
    if extractsws == 1
        
        run p_extract_sws.m
        
        % Adapt savefile name
        str_savefile = strrep(str_savefile, 'preProcessing', 'SWS');
        
        
    end
    
    
    
    % ---------------------------------------------------------------------
    if rejectchans == 1
        
        run p_chan_reject.m
        
        % Adapt savefile name
        str_savefile = strrep(str_savefile, 'preProcessing', 'ChanRej');
        
        
    end
    
    
    
    % ---------------------------------------------------------------------
    if filter == 1
        
        run p_filter.m
        
        % Adapt savefile name
        str_savefile = strrep(str_savefile, 'preProcessing', 'Filt');
        
        
    end
    
    
    
    % ---------------------------------------------------------------------
    if medianfilter == 1
        
        run p_spike_rejection.m
        
        % Adapt savefile name
        str_savefile = strrep(str_savefile, 'preProcessing', 'MedFilt');
        
        
    end
    
    
    
    %% Save dataset
    %  ============
    
    EEG = pop_saveset( EEG, 'filename', str_savefile, ...
        'filepath', savePath);
    
    
    
end