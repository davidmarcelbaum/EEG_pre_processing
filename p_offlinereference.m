[EEG, lst_changes{end+1,1}] = pop_reref( EEG, [], ...
    'exclude', find(strcmp({EEG.chanlocs.description}, 'Noisy')));

[EEG, lst_changes{end+1,1}] = eeg_checkset( EEG );
