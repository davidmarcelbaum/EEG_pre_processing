% Here, we will define the filter parameters to apply during pre-processing
% of the EEG data.

% |===USER INPUT===|
pm.response             = 'bandpassfir';% Type of filter to apply {'string'}
pm.filtOrder            = 100;          % scalar
pm.SampleRate           = 1000;         % Acquisition rate of data
pm.PassbandFrequency1   = 0.5;          % Output of frequencies inside
                                        % passband will be 100%
pm.StopbandFrequency1   = 0.45;         % Below this frequency, signal is
                                        % attenuated by set attenuation
pm.PassbandFrequency2   = 45;
pm.StopbandFrequency2   = 50;           % Above this frequency, signal is
                                        % attenuated by setattenuation
pm.StopbandAttenuation1 = 90;           % Attenuation of signal amplitude
                                        % (- Value in dB)
pm.StopbandAttenuation2 = 20;

pm.PassbandRipple       = 1;            % Not sure, what this is, but seems
                                        % to be allowed dB variations in
                                        % passband frequencies
pm.DesignMethod         = 'kaiserwin';  % Step-wise reduction in signal
                                        % amplitude
                                        % Windowed such as kaiserwin allows
                                        % for high roll-off in transition
                                        % fr band while maintaining
                                        % relatively low but significant
                                        % ripples in both passband and
                                        % stopband.
                                        % Butter IIR design allows for
                                        % minimal Ripples but does not
                                        % allow for high roll-off and
                                        % produces overshoot into Passband!
% |=END USER INPUT=|


%% Extract current recording in for non-destructive computing
dataIn = EEG.data;
if isa(dataIn, 'single')
    dataIn = double(dataIn);
end


%% Build the filter
designedFilt = designfilt(pm.response, ...
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
% fvtool(designedFilt) % plot the frequency response
% fvtool(designedFilt, 'MagnitudeDisplay', 'Zero-phase')

fprintf('\n<!> Applying filtilt. Make some coffee, this will take a while...')

% Filtfilt is working along the first dimension of matrices.
% Therefore, [timepoints x channels]
dataIn = dataIn';
dataOut = filtfilt(designedFilt, dataIn);
dataOut = dataOut';

% dataOut = nan(size(dataIn, 1), size(dataIn, 2));
% for i_chan = 1 : size(dataIn, 1)
%     fprintf(char(strcat({' '}, num2str(i_chan))));
%     % Channel-wise filtering might prevent PC lockup?
%     dataOut(i_chan, :) = filtfilt(designedFilt, dataIn(i_chan, :));
% end



%% Parsing back the data matrix to EEG structure and saving the step
EEG.data = dataOut;

clear dataIn dataOut

lst_changes{end+1,1} = designedFilt;

fprintf(' DONE!\n')
