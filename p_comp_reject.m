% |===USER INPUT===|
noiseICFile   = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/IC_rejection_info.mat';
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


% Order: EEG, components, plotag, keepcomp
EEG = pop_subcomp( EEG, v_ICs, 0, 0);
% Careful, setting keepcomp to 1 will reject components NOT provided by
% 'components'