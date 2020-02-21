%% 2. Extract SWS (2, 3 and 4)
%  ===========================

% -------------------------------------------------------------------------
% Here, we look for the sleep scoring file corresponding to the subject and
% session of recording

% |===USER INPUT===|
str_subjscore           = strcat('s', str_subjnum);
str_sessionscore        = strcat('n', str_session);
% |=END USER INPUT=|


% Locate the file of sleep scoring for subject
idx_subj    = find(contains({ls_score.name}, str_subjscore));
idx_session = find(contains({ls_score.name}, str_sessionscore));

idx_score   = intersect(idx_subj, idx_session);

if numel(idx_score) > 1 % Avoid mismatches in file processing
    error('Name of sleep scoring file not sufficiently defined')
end
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% We define structure of sleep scoring file and then import values

% |===USER INPUT===|
dataTypeScore           = '%f %f'; % Type of data content of file
column_of_interest      = 1; % Which column contains the scoring values
str_delimiter           = ' ';
% |=END USER INPUT=|


% We need to create a file identifier in order to scan it
fid_score = fopen(...
    [pathSleepScore filesep ls_score(idx_score).name]);

[v_sleepStages] = textscan(...
    fid_score, dataTypeScore, ...
    'Delimiter', str_delimiter, ...
    'CollectOutput', 1, ...
    'Headerlines', 0);
% Sleep stage values now stored in columns of cell array

v_sleepStages   = cell2mat(v_sleepStages);
v_sleepStages   = v_sleepStages(:,column_of_interest);
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% Define Slow Wave Sleep periods (SWS)
startpos_sws = find(v_sleepStages == sleepStages);
pnts_scoring = chunk_scoring * EEG.srate; % Time points to extract
% from each scoring


% Convert positions into latencies

v_data = nan(...
    size(EEG.data ,1), ...
    numel(startpos_sws) * pnts_scoring)