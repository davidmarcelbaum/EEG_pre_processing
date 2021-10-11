% ---------------------------------------------------------------------
% Define path to file that contains the channel labels that will be
% set to zero and therefore be ignored during re-referencing and
% ICA. The file has to be organized as follows in a 'variable':
% Column 1: Array of string cells that hold the "str_subject_short"
% Column 2: Cell array of channel labels that are noisy

% |===USER INPUT===|
noiseChanFile   = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\channel_rejection_info.mat';
def_variable    = 'channel_rejection';  % Name of variable that holds the 
                                        % cell of subject-wise information
                                        % of noisy channels
% |=END USER INPUT=|


% -----------------------------------------------------------------
% Extract the indices of the channels that are given by the
% sideloaded file

noiseChans = load(noiseChanFile);

subj_row = find(strcmp(noiseChans.(def_variable)(:,1), ...
    str_base));

label_chans = noiseChans.(def_variable){subj_row,2};


idx_chan2zero = zeros(numel(label_chans),1);
for i = 1 : numel(label_chans)
    
    idx_chan2zero(i) = find(strcmp(label_chans(i), ...
        {EEG.chanlocs.labels}));
    
end


% -----------------------------------------------------------------
% Here, we set these channels to zeros and adapt the EEG.chanlocs
% structure

if ~any(idx_chan2zero == 0)
    
    EEG.data(idx_chan2zero, :) = zeros;
    
    for j = 1 : numel(idx_chan2zero)
        EEG.chanlocs(idx_chan2zero(j)).description = 'Noisy';
    end
    
end