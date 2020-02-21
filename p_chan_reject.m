%% Some pre-defined variables
%  ==========================

% -------------------------------------------------------------------------
labels2search   = chanRej(~strcmp(chanRej, 'EMPTY'));

% Plot channels with labels
figure; plot3([EEG.chanlocs.X],[EEG.chanlocs.Y],[EEG.chanlocs.Z],...
    'o','MarkerFaceColor', [0 0 1]);
text([EEG.chanlocs.X],[EEG.chanlocs.Y],[EEG.chanlocs.Z],...
    {EEG.chanlocs.labels})
