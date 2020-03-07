chans2Rej           = [chan_Mastoids, chan_EOG, chan_EMG, ...
                        chan_VREF, chan_Face];
                    

% This below will generate a value in the "description" field of chanlocs.
% This will be used later in order to exclude easily channels that do not
% have an empty description field. Empty fields are EEG channels.
idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chan_Mastoids)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_Mastoids(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).type = 'Mastoid';
    end
end


idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chan_EOG)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_EOG(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).type = 'EOG';
    end
end


idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chan_EMG)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_EMG(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).type = 'EMG';
    end
end


idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chan_VREF)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_VREF(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).type = 'VREF';
    end
end


idx_chan2reject = []; % Label of empty channels
for i = 1 : numel(chan_Face)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_Face(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).type = 'Face';
    end
end


idx_chan2reject = [];
for i = 1 : numel(chans2Rej)
    idx_chan2reject = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans2Rej(i))));
    if ~isempty(idx_chan2reject)
        EEG.chanlocs(idx_chan2reject).description = 'To_exlude';
    end
end


% % Backup time series of channels that will be rejected
% EEG.rejecteddata        = EEG.data(idx_chan2reject, :);
% EEG.rejectedchanlocs    = {EEG.chanlocs(idx_chan2reject)};
% 
% 
% 
% % Remove channels competely from dataset.
% % +----------------------------------------------+
% % |This will also remove out of bounds events    |
% % |and also adapted EEG.chanlocs to kept channels|
% % +----------------------------------------------+
% [EEG, lst_changes{end+1,1}] = ...
%     pop_select( EEG, 'nochannel', idx_chan2reject);
