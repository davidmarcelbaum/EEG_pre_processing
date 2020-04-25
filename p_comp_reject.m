% |===USER INPUT===|
noiseICFile   = '/home/sleep/Desktop/DavidExploringFilterDesigns/preProcessing/ICAweightsCustomKaiserwinFilter/IC_rejection_info_CustomFilt.mat';
def_variable    = 'comps2reject';
% Name of variable that holds the cell of subject-wise information of noisy
% periods
% |=END USER INPUT=|


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
EEG = pop_subcomp( EEG, v_ICs, 0, 0);
% Careful, setting keepcomp to 1 will reject components NOT provided by
% 'components'