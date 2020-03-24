% -------------------------------------------------------------------------
% Define path to file that contains the periods that will be rejected:
% Column 1: Array of string cells that hold the "str_subject_short"
% Column 2: Cell array of period matrix (columns 1 and 2 are beginning and
% end of periods to reject, respectively)

% |===USER INPUT===|
noiseChanFile   = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/period_rejection_info.mat';
def_variable    = 'period_rejection';  % Name of variable that holds the 
                                        % cell of subject-wise information
                                        % of noisy periods
% |=END USER INPUT=|


% -------------------------------------------------------------------------
% Extract the vectors of the noisy periods that are given by the
% sideloaded file

noisePeriods = load(noiseChanFile);

subj_row = find(strcmp(noisePeriods.(def_variable)(:,1), ...
    str_subject_short));


v_periods = noisePeriods.(def_variable){subj_row,2};


if isempty(v_periods)
    return
end


% -------------------------------------------------------------------------
% The vectors are given in seconds. Here we will have to adapt them to
% latencies of the EEG structure and then substract 1 time point from the
% end edge of periods to be rejected.

v_periods = v_periods .* EEG.srate;

v_periods(:, 2) = v_periods(:, 2);

if strcmp(noisePeriods.(def_variable){subj_row,3}, 'end')
   
    v_periods(end, 2) = EEG.times(end);
    
end


[EEG, lst_changes{end+1,1}] = eeg_eegrej( EEG, v_periods);
% This should adapt the values of the latencies to the new EEG.times
