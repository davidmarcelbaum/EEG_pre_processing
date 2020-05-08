% EEG.chanlocs.description has been set to 'Noisy' for noisy channels in
% step 'Reject channels'
v_noiseChans = find(strcmp({EEG.chanlocs.description}, 'Noisy'));

if isempty(v_noiseChans)
    return
end

% Check for correct indexing
for s_chan = 1 : numel(v_noiseChans)
    if any(EEG.data(v_noiseChans(s_chan)) ~= 0)
        error('You were about to interpolate a non_empty channel')
    end
end

[EEG, EEG.lst_changes{end+1,1}] = ...
    pop_interp(EEG, [v_noiseChans], 'spherical');

for s_chan = 1 : numel(v_noiseChans)
    EEG.chanlocs(v_noiseChans(s_chan)).description = 'Interpolated';
end