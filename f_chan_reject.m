function [EEG, lst_changes] = f_chan_reject(EEG, chans, removechans)

c_chans     = fieldnames(chans);
chans2Rej   = [];
for i_fld = 1:numel(c_chans)
    
    if any(strcmp(removechans, c_chans(i_fld)))
        chans2Rej   = [chans2Rej, chans.(char(c_chans(i_fld)))];
    end
end

% ---------------------------------------------------------------------
% Here, we will only label channels that are to be ignored as 'to_exclude' 
% in description field and label the type of channel in type field.

% This below will generate a value in the "description" field of chanlocs.
% This will be used later in order to exclude easily channels that do not
% have an empty description field. Empty fields are EEG channels.
for i = 1 : numel(chans.Mastoid)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans.Mastoid(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'Mastoid';
    end
end


for i = 1 : numel(chans.EOG)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans.EOG(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'EOG';
    end
end


for i = 1 : numel(chans.EMG)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans.EMG(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'EMG';
    end
end


for i = 1 : numel(chans.Face)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans.Face(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'Face';
    end
end

for i = 1 : numel(chans.VREF)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans.VREF(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).type = 'VREF';
    end
end


for i = 1 : numel(chans2Rej)
    idx_label = find(strcmp( ...
        {EEG.chanlocs.labels}, char(chans2Rej(i))));
    if ~isempty(idx_label)
        EEG.chanlocs(idx_label).description = 'To_exlude';
    end
end


% ---------------------------------------------------------------------
% Here, we will actually remove the channels entirely from EEG.data and
% EEG.chanlocs as well as EEG.nbchan

idx_chan2rej = find(strcmp({EEG.chanlocs.description}, 'To_exlude'));


% % Backup time series of channels that will be rejected
% EEG.rejecteddata        = EEG.data(idx_chan2rej, :);
% EEG.rejectedchanlocs    = EEG.chanlocs(idx_chan2rej);


% Remove channels competely from dataset.
% +----------------------------------------------+
% |This will also remove out of bounds events    |
% +----------------------------------------------+
[EEG, lst_changes] = ...
    pop_select( EEG, 'nochannel', idx_chan2rej);
% The 'nochannel' option will adapt EEG.chanlocs and EEG.nbchan



end