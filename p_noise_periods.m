% -------------------------------------------------------------------------
% Define path to file that contains the periods that will be rejected:
% Column 1: Array of string cells that hold the "str_subject_short"
% Column 2: Cell array of period matrix (columns 1 and 2 are beginning and
% end of periods to reject, respectively)

% |===USER INPUT===|
noiseChanFile   = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\period_rejection_info.mat';
def_variable    = 'period_rejection';  % Name of variable that holds the 
                                        % cell of subject-wise information
                                        % of noisy periods
% |=END USER INPUT=|


% -------------------------------------------------------------------------
% Extract the vectors of the noisy periods that are given by the
% sideloaded file

noisePeriods = load(noiseChanFile);

subj_row = find(strcmp(noisePeriods.(def_variable)(:,1), ...
    str_base));


v_periods = noisePeriods.(def_variable){subj_row,2};


% -------------------------------------------------------------------------
% The vectors are given in seconds. Here we will have to adapt them to
% latencies of the EEG structure.

v_periods           = v_periods .* EEG.srate;



% Determine percentage of noise in recording
if isempty(v_periods)
    Perc_noise(s_file, 1)   = 0;
    return
else
    Length_noise            = v_periods(:, 2) - v_periods(:, 1);
    Perc_noise(s_file, 1)   = sum(Length_noise) / numel(EEG.times);
end


if strcmp(noisePeriods.(def_variable){subj_row,3}, 'end')
   
    v_periods(end, 2) = EEG.times(end);
    
end 

[EEG, lst_changes{end+1,1}] = eeg_eegrej( EEG, v_periods);
% This should adapt the values of the latencies to the new EEG.times
