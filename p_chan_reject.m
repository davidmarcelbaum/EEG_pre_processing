% Looking up position of channels to be rejected

idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chans2Rej)
    idx_chan2reject(end+1) = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans2Rej(i))));
end


idx_chan2reject = sort(idx_chan2reject);


% Backup time series of channels that will be rejected
EEG.rejectedData    = EEG.data(idx_chan2reject, :);
EEG.rejectedChans   = {EEG.chanlocs(idx_chan2reject).labels};



% Remove channels competely from dataset.
% +----------------------------------------------+
% |This will also remove out of bounds events    |
% |and also adapted EEG.chanlocs to kept channels|
% +----------------------------------------------+
[EEG, lst_changes{end+1,1}] = ...
    pop_select( EEG, 'nochannel', idx_chan2reject);