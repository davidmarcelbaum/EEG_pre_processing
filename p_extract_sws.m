%% Some pre-defined variables
%  ==========================

% -------------------------------------------------------------------------
% This will be used to establish the time points to extract from EEG.data
pnts_scoring            = chunk_scoring * EEG.srate;

EEG.sleepscorelabels    = { 'Awake', 0;     ...
                            'REM', 5;       ...
                            'NREM1', 1;     ...
                            'NREM2', 2;     ...
                            'NREM3', 3;     ...
                            'NREM4', 4;     ...
                            'MT', 8         };
                  

                        
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


% -------------------------------------------------------------------------
% We define structure of sleep scoring file and then import values

% |===USER INPUT===|
dataTypeScore       = '%f %f'; % Type of data content of file
column_of_interest  = 1; % Which column contains the scoring values
str_delimiter       = ' ';
% |=END USER INPUT=|


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


% Since startpos_sws is a position-in-vector variable, we convert the
% values to latencies according to the actual recording values and then
% extract the time series from the recording data
v_data      = zeros(size(EEG.data ,1), numel(startpos_sws) * pnts_scoring);
v_times     = zeros(1, numel(startpos_sws) * pnts_scoring);
for pos_sws = 1 : numel(startpos_sws)
    
    % Start and stop latency of the imported dataset
    start_latency   = startpos_sws(pos_sws) * pnts_scoring - ...
        pnts_scoring + 1;
    stop_latency    = start_latency + pnts_scoring - 1;
    
    % Start and end in our time vectors, not the imported dataset
    start_pnt       = pos_sws * pnts_scoring - pnts_scoring + 1;
    stop_pnt        = pos_sws * pnts_scoring;
    
    % Extract data points and latencies from dataset and store in data and
    % time vector
    v_data(:, start_pnt:stop_pnt)   = EEG.data(:, ...
        start_latency:stop_latency);
    v_times(start_pnt:stop_pnt)     = start_latency:stop_latency;
    
end


% -------------------------------------------------------------------------
% Assign EEGLAB structures to the extracted values

EEG.data                = v_data;
EEG.sleepscores         = v_sleepStages;
EEG.pnts                = size(EEG.data, 2);
EEG.times               = 1:size(EEG.data, 2); % is continuous
EEG.timesSWS            = v_times; % are the actual time latencies extracted
