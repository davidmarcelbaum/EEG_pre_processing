function [EEGout, lst_changes] = f_interpolate(EEGin, channel_types)

% EEG.chanlocs.description has been set to 'Noisy' for noisy channels in
% step 'Reject channels'
v_noiseChans = [];
for i_type = 1:numel(channel_types)
    v_noiseChans = [v_noiseChans, ...
        find(strcmp({EEGin.chanlocs.description}, channel_types(i_type)))];
end

if isempty(v_noiseChans)
    EEGout = EEGin;
    lst_changes = 'EEG = pop_interp(EE, "none required")';
    return
end

% Check for correct indexing
for s_chan = 1 : numel(v_noiseChans)
    if any(EEGin.data(v_noiseChans(s_chan)) ~= 0)
        error('You were about to interpolate a non_empty channel')
        % Noisy channels should be:
        % 1. EEG.chanlocs.description = 'Noisy'
        % 2. EEG.data = zeros
    end
end

[EEGout] = pop_interp(EEGin, v_noiseChans, 'spherical');

lst_changes = strcat("EEG = pop_interp(EEG, [", ...
    num2str(v_noiseChans), "], 'spherical'");

for s_chan = 1 : numel(v_noiseChans)
    EEGout.chanlocs(v_noiseChans(s_chan)).description = 'Interpolated';
end

end