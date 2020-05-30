% |===USER INPUT===|
filt_highpass       = 0.1;
filt_lowpass        = 45;
filter_length       = 33000; % 66000 seems better, try to further increase
% Frequencies to use as boundaries for filtering and filter "steeepness".
% The lower the filt order, the higher the filter length and the steeper
% the cutoff frequency
% |=END USER INPUT=|


% THE ERROR HERE SEEMS TO HAVE BEEN CAUSED BY CHANNEL VREF OF ZEROS!
%
%         try % This here should not be done twice, but it does not always
%             % seem to work the first time. NEEDS CHECKING AND CORRECTION
%             [EEG, lst_changes{end+1}] = pop_eegfiltnew( EEG, ...
%                 'locutoff', filt_highpass, 'hicutoff', filt_lowpass, ...
%                 'filtorder', 33000);
%             % Filtorder = filter length - 1; filter length: how many
%             % weighted data points X compose filtered data Y
%
%         catch ME
%
%             if strcmp(ME.message, ...
%                     'Attempt to grow array along ambiguous dimension.')
%
%                 fprintf('HELLO THERE!!!!!!!')
%                 wait(1)
%
%                 [EEG, lst_changes{end+1}] = pop_eegfiltnew( EEG, ...
%                     'locutoff', filt_highpass, 'hicutoff', filt_lowpass, ...
%                     'filtorder', 33000);
%                 % Filtorder = filter length - 1; filter length: how many
%                 % weighted data points X compose filtered data Y
%                 % Try again, it works the second time...
%
%             end
%         end


[EEG, lst_changes{end+1}] = pop_eegfiltnew( EEG, ...
    'locutoff', filt_highpass, 'hicutoff', filt_lowpass, ...
    'filtorder', filter_length, 'plotfreqz', 0);
% Filtorder = filter length - 1; filter length: how many
% weighted data points X compose filtered data Y

% Check data integrity
[EEG, lst_changes{end+1,1}] = eeg_checkset( EEG );