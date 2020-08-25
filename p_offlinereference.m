% [EEG, lst_changes{end+1,1}] = pop_reref( EEG, [], ...
%     'exclude', find(strcmp({EEG.chanlocs.description}, 'Noisy')));
% 
% [EEG, lst_changes{end+1,1}] = eeg_checkset( EEG );

[EEG_Sham, lst_changes{end+1,1}] = pop_reref( EEG_Sham, [], ...
    'exclude', find(strcmp({EEG_Sham.chanlocs.description}, 'Noisy')));

[EEG_Sham, lst_changes{end+1,1}] = eeg_checkset( EEG_Sham );

[EEG_Odor, lst_changes{end+1,1}] = pop_reref( EEG_Odor, [], ...
    'exclude', find(strcmp({EEG_Odor.chanlocs.description}, 'Noisy')));

[EEG_Odor, lst_changes{end+1,1}] = eeg_checkset( EEG_Odor );
