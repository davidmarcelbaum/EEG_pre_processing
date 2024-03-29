function [structEEG, lst_changes] = f_ica(structEEG)

[structEEG] = pop_runica(structEEG, ...
    'icatype',      'runica', ...
    'extended',     1, ...
    'interrupt',    'off', ...
    'chanind',      find(~strcmp({structEEG.chanlocs.description}, 'Noisy')));
% chanind are the channel indices to INCLUDE (reverse strcmp)

lst_changes = {strcat('Ran ICA excluding channels:', {' '}, ...
    num2str(find(strcmp({structEEG.chanlocs.description}, ...
    'Noisy'))), ...
    ' (If empty, then no channel exlcuded)')};

[structEEG, lst_changes{end+1,1}] = eeg_checkset( structEEG );

end