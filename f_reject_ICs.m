function [EEG, lst_changes] = f_reject_ICs(EEG, noiseICFile, def_variable)

global str_base

% -------------------------------------------------------------------------
% Extract the vectors of the noisy periods that are given by the
% sideloaded file

artifactualICs = load(noiseICFile);

subj_row = find(strcmp(artifactualICs.(def_variable)(:,1), ...
    str_base));


v_ICs = artifactualICs.(def_variable){subj_row,2};


if isempty(v_ICs)
    return
end

fprintf('\n<!> Eliminating %d component(s)\n', numel(v_ICs))

% Order: EEG, components, plotag, keepcomp
[EEG, lst_changes] = pop_subcomp( EEG, v_ICs, 0, 0);
% Careful, setting keepcomp to 1 will reject components NOT provided by
% 'components'