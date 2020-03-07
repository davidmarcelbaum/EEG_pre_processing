[EEG, lst_changes{end+1}] = pop_eegfiltnew( EEG, ...
    'locutoff', filt_highpass, 'hicutoff', filt_lowpass, ...
    'filtorder', 33000);
% Filtorder = filter length - 1; filter length: how many
% weighted data points X compose filtered data Y

% Check data integrity
[EEG, lst_changes{end+1,1}] = eeg_checkset( EEG );