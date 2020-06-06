% |===USER INPUT===|
chan_Mastoids       = {'M1', 'M2'};
chan_EOG            = {'HEO', 'VEO'};
chan_EMG            = {'EMG'};
chan_VREF           = {};
chan_EKG           = {'EKG'};
% Cell arrays of strings that specifies the channels to reject from
% datasets.

destructive_mode    = 1;    % [0, 1] for false and true
                            % Choose here whether to reject channels in
                            % destructive mode (complete rejection from
                            % dataset) or reversible rejection (only
                            % labeling channels as to be ignored in
                            % pre-processing steps such as ICA).
% |=END USER INPUT=|


chans2Rej   = [chan_EOG, chan_EMG, chan_EKG];


for i = 1:numel(chans2Rej)
   idx_chan2rej(i) = find(strcmp({EEG.chanlocs.labels},chans2Rej(i)));
    
end
    
    
    % Remove channels competely from dataset.
    % +----------------------------------------------+
    % |This will also remove out of bounds events    |
    % +----------------------------------------------+
    [EEG, lst_changes{end+1,1}] = ...
        pop_select( EEG, 'nochannel', idx_chan2rej);
    % The 'nochannel' option will adapt EEG.chanlocs and EEG.nbchan
    
