% Here, we will define the filter parameters to apply during pre-processing
% of the EEG data.

% |===USER INPUT===|
pm.response             = 'bandpassfir';% Type of filter to apply {'string'}
% pm.filtOrder            = 33;           % scalar
pm.SampleRate           = EEG.srate;    % Acquisition rate of data
pm.StopbandFrequency1   = 0.5;          % Below this frequency, signal is 
                                        % attenuated by set attenuation
pm.StopbandFrequency2   = 50;           % Above this frequency, signal is 
                                        % attenuated by setattenuation
pm.StopbandAttenuation1 = 100;          % Attenuation of signal amplitude 
                                        % (- Value in dB)
pm.StopbandAttenuation2 = 70;

pm.PassbandRipple       = 1;            % Not sure, what this is, but seems
                                        % to be allowed dB variations in 
                                        % passband frequencies
pm.PassbandFrequency1   = 0.75;
pm.PassbandFrequency2   = 45;           % Output of frequencies inside 
                                        % passband will be 100%
pm.DesignMethod         = 'kaiserwin';  % Step-wise reduction in signal 
                                        % amplitude
% |=END USER INPUT=|


%% Extract current recording in for non-destructive computing
dataIn                      = EEG.data;
if isa(dataIn, 'single')
    dataIn = double(dataIn);
end


%% Build the filter

% designedFilt = designfilt('highpassfir', ...
%     'StopbandFrequency',      pm.StopbandFrequency,           ...
%     'PassbandFrequency',      pm.PassbandFrequency,           ...
%     'StopbandAttenuation',    pm.StopbandAttenuation,         ...
%     'PassbandRipple',         pm.PassbandRipple,              ...
%     'SampleRate',             pm.SampleRate,                  ...
%     'DesignMethod',           pm.DesignMethod);

designedFilt = designfilt('bandpassfir', ...
    'SampleRate',           pm.SampleRate,              ...
    'StopbandAttenuation1', pm.StopbandAttenuation1,    ...
    'StopbandAttenuation2', pm.StopbandAttenuation2,    ...
    'PassbandFrequency1',   pm.PassbandFrequency1,      ...
    'PassbandFrequency2',   pm.PassbandFrequency2,      ...
    'StopbandFrequency1',   pm.StopbandFrequency1,      ...
    'StopbandFrequency2',   pm.StopbandFrequency2,      ...
    'PassbandRipple',       pm.PassbandRipple,          ...
    'DesignMethod',         pm.DesignMethod);

% The length of the input X must be more than three times the filter order,
% defined as max(length(B)-1,length(A)-1)
fvtool(designedFilt) % plot the frequency response
fvtool(designedFilt, 'MagnitudeDisplay', 'Zero-phase')

% ERROR SAMPLE NUMBER: 76938 / 3 = 25645 = filtOrder
% There is an error when parsing the data matrix as number of channels x
% number of time points and it seems to be caused by the fact that filtfilt
% is taking the number of chans and time points
dataIn = dataIn';

fprintf('\n<!> Applying filtilt. Make some coffee, this will take a while...')

dataOut = filtfilt(designedFilt, dataIn);


%% For verification, get power spectrum (in dB)

% params.fpass    = [0 45];
% params.Fs       = pm.SampleRate;
% params.tapers   = [0 100];
% params.trialave = 0;
% params.err      = 0;
% [v_peaks,v_freqs]    = mtspectrumc(dataOut(2,:), params); 
% plot(v_freqs,v_peaks, 'LineWidth', 0.5, 'Color', 'b')



%% Parsing back the data matrix to EEG structure and saving the step
EEG.data = dataOut';

clear dataIn dataOut

lst_changes{end+1,1} = strcat('customfilt(', 'bandpassfir', ...
    '_SampleRate',           num2str(pm.SampleRate),              ...
    '_StopbandAttenuation1', num2str(pm.StopbandAttenuation1),    ...
    '_StopbandAttenuation2', num2str(pm.StopbandAttenuation2),    ...
    '_PassbandFrequency1',   num2str(pm.PassbandFrequency1),      ...
    '_PassbandFrequency2',   num2str(pm.PassbandFrequency2),      ...
    '_StopbandFrequency1',   num2str(pm.StopbandFrequency1),      ...
    '_StopbandFrequency2',   num2str(pm.StopbandFrequency2),      ...
    '_PassbandRipple',       num2str(pm.PassbandRipple),          ...
    '_DesignMethod',         pm.DesignMethod);

fprintf(' DONE!\n')
