function [EEGout, lst_changes] = f_offlinereference(EEGin)

[EEGout, lst_changes] = pop_reref( EEGin, [], ...
    'exclude', find(strcmp({EEGin.chanlocs.description}, 'Noisy')));

end
