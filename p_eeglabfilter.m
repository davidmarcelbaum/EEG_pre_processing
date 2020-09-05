% |===USER INPUT===|
filt_highpass       = 0.1;
filt_lowpass        = 45;
filter_length       = 33000; % 66000 seems better, try to further increase
% Frequencies to use as boundaries for filtering and filter "steeepness".
% The lower the filt order, the higher the filter length and the steeper
% the cutoff frequency
% |=END USER INPUT=|


[EEG, lst_changes{end+1,1}] = pop_eegfiltnew( EEG, ...
    'locutoff', filt_highpass, 'hicutoff', filt_lowpass, ...
    'filtorder', filter_length, 'plotfreqz', 1);
% Filtorder = filter length - 1; filter length: how many
% weighted data points X compose filtered data Y

% Check data integrity
[EEG, lst_changes{end+1,1}] = eeg_checkset( EEG );