function [EEG, lst_changes] = f_sleep_as_epoch(EEG, ...
    str_subjnum, str_session)

% |===USER INPUT===|
pathSleepScore      = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\Hypnograms\';
% String of file path to the mother stem folder containing the files of
% sleep scoring of the subjects. LEAVE EMPTY ("''") IF DOES NOT APPLY

dataTypeScore       = '%f %f';  % Type of data content of file
column_of_interest  = 1;        % Which column contains the scoring values
str_delimiter       = ' ';
% We define structure of sleep scoring file and then import values

chunk_scoring       = 30; % scalar (s)
% What was the scoring interval (in seconds)

EEG.sleepscorelabels = { ...
    'Awake',    0;     ...
    'REM',      5;     ...
    'NREM1',    1;     ...
    'NREM2',    2;     ...
    'NREM3',    3;     ...
    'NREM4',    4;     ...
    'MT',       8;     ...
    'All',      NaN};
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



%% 2. Extract sleep stages
%  =======================
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

for iStage = 1:size(EEG.sleepscorelabels, 1)
    
    currStage = EEG.sleepscorelabels{iStage, 2};
    
    if ~isnan(currStage)
        validSleepStages    = zeros(numel(v_sleepStages), 1);
        validSleepStages(v_sleepStages == currStage) = 1;
    else
        validSleepStages    = ones(numel(v_sleepStages), 1);
    end
    
    startpos_sws        = find(validSleepStages == 1);
    
    
    %% Extract sleep stage times
    %  ------------------------------------------------------------------------
    
    
    
    for pos_sws = 1 : numel(startpos_sws)
        
        % Start and stop latency of time blocks to be retained
        time_borders(1,pos_sws)   = startpos_sws(pos_sws) * pnts_scoring - ...
            pnts_scoring + 1;
        time_borders(2,pos_sws)   = time_borders(1,pos_sws) + ....
            pnts_scoring - 1;
        
    end
    
    i = 0;
    
    if isempty(startpos_sws)
       
        EEG.(char(EEG.sleepscorelabels{iStage, 1})) = [];
        continue
        
    end
    
    
    for v_rej = 1 : size(time_borders, 2)
        
        % Build a matrix with limits of data blocks to reject
        if v_rej == 1 && time_borders(1,1) == 1
            
            continue        
        
        elseif v_rej == 1 && time_borders(1,1) > 1
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
    
    [EEGTmp] = eeg_eegrej( EEG, out_of_bound);
    % This should adapt the values of the latencies to the new EEG.times
    
    
    % Last check for data integrity and correct SWS period extraction.
    % This check obviously does not apply to datasets in which last SWS
    % period was exceeding oiginal length of recording
    if time_borders(2, end) < ori_pnts && ...
            EEGTmp.pnts ~= pnts_scoring * numel(startpos_sws)
        
        error('Mismatch between final dataset time points and number of SWS periods')
        
    elseif time_borders(2, end) > ori_pnts
        
        warning('SWS periods did not allow for end extracton data verification. You can ignore this.')
        
    end
    
    % ---------------------------------------------------------------------
    % Cleanup in order to avoid errors in current subject in remaining
    % lines in these variables when previous subject had more borders.
    
    clear time_borders out_of_bound
    
    %% Slice datasets
    
    epoch_edges_seconds     = [-15, 15]; % seconds around epoch midpoint
    epoch_edges             = epoch_edges_seconds * EEG.srate;
    % Checkpoint
    if mod(EEGTmp.pnts / sum(abs(epoch_edges)), 1) ~= 0
        error('Data samples do not match 30 second sleep scores')
    end
    
    
    trial_time_stamps = 15*EEG.srate:sum(abs(epoch_edges)):EEG.pnts;
    
    % Purge existing non-desired events from structure
    EEGTmp.event(1:length(EEGTmp.event)) = [];
    
    for iTrial = 1:numel(trial_time_stamps)
        
        EEGTmp.event(iTrial).latency = trial_time_stamps(iTrial);
        EEGTmp.event(iTrial).type    = 'SleepEpoch';
        
    end
    
    [EEGTmp] = pop_epoch(EEGTmp, ...
        {EEGTmp.event(1:numel(trial_time_stamps)).type}, ...
        epoch_edges_seconds);
    
    
    
    EEG.(char(EEG.sleepscorelabels{iStage, 1})) = EEGTmp.data;
    EEGTmp = [];
    
    
end

sum_samples = 0;
for iStage = 1:size(EEG.sleepscorelabels, 1)
    
    curr_data = EEG.(char(EEG.sleepscorelabels{iStage, 1}));
    if isempty(curr_data) || strcmp(EEG.sleepscorelabels{iStage, 1}, 'All')
        continue
    end
    
    sum_samples = sum_samples + size(curr_data, 2) * size(curr_data, 3);
    
end

if sum_samples > size(EEG.data, 2)
    error('Overlap in sleep stages')
end

EEG.data    = []; % Avoid datasets from being too large
EEG.times   = [];
EEG.event   = [];
lst_changes = 'By sleep stage extraction';


end