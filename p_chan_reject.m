% |===USER INPUT===|
chan_Mastoids       = {'E57', 'E100'};
chan_EOG            = {'E8', 'E14', 'E21', 'E25', 'E126', 'E127'};
chan_EMG            = {'E43', 'E120'};
chan_VREF           = {'E129'};
chan_Face           = {'E49', 'E48', 'E17', 'E128', 'E32', 'E1', ...
                        'E125', 'E119', 'E113'};
% Cell arrays of strings that specifies the channels to reject from
% datasets.

destructive_mode    = 1;    % [0, 1] for false and true
                            % Choose here whether to reject channels in
                            % destructive mode (complete rejection from
                            % dataset) or reversible rejection (only
                            % labeling channels as to be ignored in
                            % pre-processing steps such as ICA).
% |=END USER INPUT=|


chans2Rej   = [chan_Mastoids, chan_EOG, chan_EMG, chan_Face, chan_VREF];

% ---------------------------------------------------------------------
% Here, we will only label channels that are to be ignored as 'to_exclude' 
% in description field and label the type of channel in type field.

% This below will generate a value in the "description" field of chanlocs.
% This will be used later in order to exclude easily channels that do not
% have an empty description field. Empty fields are EEG channels.
for i = 1 : numel(chan_Mastoids)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_Mastoids(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'Mastoid';
    end
end


for i = 1 : numel(chan_EOG)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_EOG(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'EOG';
    end
end


for i = 1 : numel(chan_EMG)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_EMG(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'EMG';
    end
end


for i = 1 : numel(chan_Face)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_Face(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'Face';
    end
end


for i = 1 : numel(chans2Rej)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans2Rej(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).description = 'To_exlude';
    end
end


for i = 1 : numel(chan_VREF)
    idx_chan2rej = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chan_VREF(i))));
    if ~isempty(idx_chan2rej)
        EEG.chanlocs(idx_chan2rej).type = 'VREF';
        % VREF to be deleted regardless of destructive_mode since only 
        % zeros and is confusing filter step later.
        idx_VREF = idx_chan2rej;
    end
end


% Remove VREF channel competely from dataset.
% +----------------------------------------------+
% |This will also remove out of bounds events    |
% +----------------------------------------------+
[EEG, lst_changes{end+1,1}] = ...
    pop_select( EEG, 'nochannel', idx_VREF);
% The 'nochannel' option will adapt EEG.chanlocs and EEG.nbchan



if destructive_mode == 1
    
    % ---------------------------------------------------------------------
    % Here, we will actually remove the channels entirely from EEG.data and
    % EEG.chanlocs as well as EEG.nbchan
    
    idx_chan2rej = find(strcmp({EEG.chanlocs.description}, 'To_exlude'));
    
    
    % Backup time series of channels that will be rejected
    EEG.rejecteddata        = EEG.data(idx_chan2rej, :);
    EEG.rejectedchanlocs    = EEG.chanlocs(idx_chan2rej);
    
    
    % Remove channels competely from dataset.
    % +----------------------------------------------+
    % |This will also remove out of bounds events    |
    % +----------------------------------------------+
    [EEG, lst_changes{end+1,1}] = ...
        pop_select( EEG, 'nochannel', idx_chan2rej);
    % The 'nochannel' option will adapt EEG.chanlocs and EEG.nbchan
    
    
end
