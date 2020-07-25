% |===USER INPUT===|
pathSleepScore      = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\Hypnograms\';
% String of file path to the mother stem folder containing the files of
% sleep scoring of the subjects. LEAVE EMPTY ("''") IF DOES NOT APPLY

dataTypeScore       = '%f %f';  % Type of data content of file
column_of_interest  = 1;        % Which column contains the scoring values
str_delimiter       = ' ';
% We define structure of sleep scoring file and then import values

use_eegrej          = 1; % [0, 1]
% Whether to use the built-in EEGLAB function eegrej in order to reject
% time blocks of EEG.data or not. The own-coded part works perfectly fine
% but I am not sure if adapting EEG.event and EEG.times is enough in the
% future when proceeding to next steps. EEGLAB might get confused. Instead,
% the builtin function eegrej should take care of adjusting everything that
% is needed. It also adds boundaries where needed which is not done in case
% of use_eegrej == 0. This might requiere additional work during epoching 
% later in order to exclude incomplete trials.

chunk_scoring       = 30; % scalar (s)
% What was the scoring interval (in seconds)

sleepStages         = [2, 3, 4]; % [scalars]
% Define the sleep stages of interest to use if scleep scoring files will
% be sideloaded

EEG.sleepscorelabels = { ...
    'Awake', 0;     ...
    'REM', 5;       ...
    'NREM1', 1;     ...
    'NREM2', 2;     ...
    'NREM3', 3;     ...
    'NREM4', 4;     ...
    'MT', 8         };
% |=END USER INPUT=|


% -------------------------------------------------------------------------
% This will be used to establish the time points to extract from EEG.data
pnts_scoring            = chunk_scoring * EEG.srate;


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


% Avoid potential errors
if strcmp(pathSleepScore(end), filesep)
    pathSleepScore(end) = [];
end
                  


%% 2. Extract SWS (2, 3 and 4)
%  ===========================
% -------------------------------------------------------------------------
% Here, we look for the sleep scoring file corresponding to the subject and
% session of recording

% |===USER INPUT===|
str_subjscore       = strcat('s', str_subjnum);
str_sessionscore    = strcat('n', str_session);
% |=END USER INPUT=|


% Locate the file of sleep scoring for subject
idx_subj            = find(contains({ls_score.name}, str_subjscore));
idx_session         = find(contains({ls_score.name}, str_sessionscore));
idx_score           = intersect(idx_subj, idx_session);


if numel(idx_score) > 1 % Avoid mismatches in file processing
    error('Name of sleep scoring file not sufficiently defined')
end


% We need to create a file identifier in order to scan it
fid_score           = fopen(...
    [pathSleepScore filesep ls_score(idx_score).name]);

[v_sleepStages]     = textscan(fid_score, dataTypeScore, ...
    'Delimiter', str_delimiter, 'CollectOutput', 1, 'Headerlines', 0);
% Sleep stage values now stored in columns of cell array


v_sleepStages       = cell2mat(v_sleepStages);
v_sleepStages       = v_sleepStages(:,column_of_interest);


% -------------------------------------------------------------------------
% Define Slow Wave Sleep periods (SWS) and extract time series of SWS

validSleepStages    = zeros(numel(v_sleepStages), 1);
for i = 1 : numel(sleepStages)
    validSleepStages(v_sleepStages == sleepStages(i)) = 1;
end

startpos_sws        = find(validSleepStages == 1);


if use_eegrej == 1
    
    for pos_sws = 1 : numel(startpos_sws)
        
        % Start and stop latency of time blocks to be retained
        time_borders(1,pos_sws)   = startpos_sws(pos_sws) * pnts_scoring - ...
            pnts_scoring + 1;
        time_borders(2,pos_sws)   = time_borders(1,pos_sws) + ....
            pnts_scoring - 1;
        
    end
    
    i = 0;
    for v_rej = 1 : size(time_borders, 2)
        
        % Build a matrix with limits of data blocks to reject
        if v_rej == 1 && time_borders(1,1) > 1
            % If first period of SWS is different from first scoring period
            
            i = i + 1;
            
            out_of_bound(i,1) = 1;
            out_of_bound(i,2) = time_borders(1,1) - 1;
            
        elseif time_borders(1, v_rej) - time_borders(2, v_rej-1) > 1
            
            i = i + 1;
            
            out_of_bound(i,1) = time_borders(2, v_rej-1) + 1;
            out_of_bound(i,2) = time_borders(1, v_rej) - 1;
            
        elseif time_borders(1, v_rej) - time_borders(2, v_rej-1) < 0
            % Jut to be sure there is no error in the time_borders array
            
            error('An error occurred in the generation of the sleep period boundaries')
            
        end
        
        
        if v_rej == size(time_borders, 2)
            
            if time_borders(2, v_rej) > EEG.times(end) + 1
                % It is possible that the last scoring period, which is 
                % created in a fixed way, exceeds the time limit of actual 
                % recording. In that case, correct the last stop point
            
                out_of_bound(i,2) = EEG.times(end) + 1;
            
            elseif time_borders(2, v_rej) < EEG.times(end) + 1
                % In tihs case, an additional boundary needs to be added
                % between last SWS period and end of recording.
                
                i = i + 1;
                
                out_of_bound(i,1) = time_borders(2, v_rej) + 1;
                out_of_bound(i,2) = EEG.times(end) + 1;
                                    % +1 because begins with 0
            
            end
            
        end
        
    end
    
    out_of_bound % Visualize
    
    ori_pnts = EEG.times(end) + 1;
    
    [EEG, lst_changes{end+1,1}] = eeg_eegrej( EEG, out_of_bound);
    % This should adapt the values of the latencies to the new EEG.times
    
    
    % Last check for data integrity and correct SWS period extraction.
    % This check obviously does not apply to datasets in which last SWS
    % period was exceeding oiginal length of recording
    if time_borders(2, end) < ori_pnts && ...
            EEG.pnts ~= pnts_scoring * numel(startpos_sws)
        
        error('Mismatch between final dataset time points and number of SWS periods')
        
    elseif time_borders(2, end) > ori_pnts
        
        warning('SWS periods did not allow for end extracton data verification. You can ignore this.')
        
    end
    
    % ---------------------------------------------------------------------
    % Cleanup in order to avoid errors in current subject in remaining 
    % lines in these variables when previous subject had more borders.
    
    clear time_borders out_of_bound
    
    
elseif use_eegrej == 0
    
    % Since startpos_sws is a position-in-vector variable, we convert the
    % values to latencies according to the actual recording values and then
    % extract the time series from the recording data
    v_data  = zeros(size(EEG.data ,1), numel(startpos_sws) * pnts_scoring);
    v_times = zeros(1, numel(startpos_sws) * pnts_scoring);
    for pos_sws = 1 : numel(startpos_sws)
        
        % Start and stop latency of the imported dataset
        start_latency   = startpos_sws(pos_sws) * pnts_scoring - ...
            pnts_scoring + 1;
        stop_latency    = start_latency + pnts_scoring - 1;
        
        % Start and end in our time vectors, not the imported dataset
        start_pnt       = pos_sws * pnts_scoring - pnts_scoring + 1;
        stop_pnt        = pos_sws * pnts_scoring;
        
        % Extract data points and latencies from dataset and store in data 
        % and time vector
        v_data(:, start_pnt:stop_pnt)   = EEG.data(:, ...
            start_latency:stop_latency);
        v_times(start_pnt:stop_pnt)     = start_latency:stop_latency;
        
    end
    
    
    % ---------------------------------------------------------------------
    % Assign EEGLAB structures to the extracted values
    
    EEG.data            = v_data;
    EEG.sleepscores     = v_sleepStages;
    EEG.pnts            = size(EEG.data, 2);
    EEG.times           = 1:size(EEG.data, 2); % is continuous
    EEG.timesSWS        = v_times; % are the actual time latencies extracted
    
    
    % ---------------------------------------------------------------------
    % IMPORTANT: Latencies of triggers in EEG.event.latency have not been
    % adapted since we did not use an in-built EEGLAB function in order to 
    % crop the time series. We need to assign the trigger latencies to the 
    % new EEG.times vector which is continuous.
    
    % Backup original events
    EEG.rejectedevent   = EEG.event;
    
    % Necessary to convert trigger latencies into integers since MATLAB
    % will not perform ismember function correctly if not.
    v_latencies         = int64([EEG.event.latency]);
    
    in_or_out = zeros(1, numel(v_latencies));
    for s_lat = 1 : numel(v_latencies)
        
        % Get the triggers that are inside the SWS time series
        in_or_out(s_lat) = ismember(v_latencies(s_lat), EEG.timesSWS);
        
    end
    
    pos_lat_in_SWS      = find(in_or_out == 1);
    pos_lat_out_SWS     = find(in_or_out == 0);
    
    for pos_lat = 1 : numel(pos_lat_in_SWS)
        
        % Find the latency in the continuous time vector
        pos_time = ...
            find(EEG.timesSWS == v_latencies(pos_lat_in_SWS(pos_lat)));
        
        EEG.event(pos_lat_in_SWS(pos_lat)).latency = pos_time;
        
    end
    
    % Lastly, we reject the triggers outside the time series from EEG.event
    EEG.event(pos_lat_out_SWS) = [];
    
    
    % ---------------------------------------------------------------------
    % Cleanup in order to allow loading of heavy variables afterwards 
    % (Subject 091 gives Java Memory Error)

    clear v_data v_times
    
    
end
