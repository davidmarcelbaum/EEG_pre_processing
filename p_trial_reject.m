% |===USER INPUT===|
noiseTrialFile   = '/home/sleep/Desktop/DavidExploringFilterDesigns/preProcessing/ICAweightsCustomKaiserwinFilter/IC_rejection_info_CustomFilt.mat';
def_variable    = 'comps2reject';
% Name of variable that holds the cell of subject-wise information of noisy
% periods
% |=END USER INPUT=|


% -------------------------------------------------------------------------
% Extract the vectors of the noisy periods that are given by the
% sideloaded file

noisyICs = load(noiseTrialFile);

global str_base
subj_row = find(strcmp(noisyICs.(def_variable)(:,1), ...
    str_base));

rej_trials = noisyICs.(def_variable){subj_row,3};


% -------------------------------------------------------------------------
% Simply reject the epochs

if ~isempty(rej_trials)
    [EEG, EEG.lst_changes{end+1,1}] = pop_rejepoch( EEG, rej_trials ,0);
end


% -------------------------------------------------------------------------
% Here, we identify triggers that are not corresponding to the defined
% mid-trial trigger type (DIN1 or DIN2) as well as incomplete trials that
% do not contain EEG.times time points between neighbouring triggers.
% At the end, the epochs will be rejected.

idx_nonMidTrigger = find(strcmp({EEG.event.code}, trialEdges));

for i_edge = 1 : numel(idx_nonMidTrigger)
   
    lat_overlap = int64(EEG.event(idx_nonMidTrigger(i_edge)).latency);
    
    if lat_overlap - numel(EEG.times) / 2 <= ...
            EEG.event(idx_nonMidTrigger(i_edge)-1).latency
        
        rej_trials(end+1) = idx_nonMidTrigger(i_edge)-1;
        rej_trials(end+1) = idx_nonMidTrigger(i_edge);
        
    elseif lat_overlap + numel(EEG.times) / 2 >= ...
            EEG.event(idx_nonMidTrigger(i_edge)+1).latency
        
        rej_trials(end+1) = idx_nonMidTrigger(i_edge)+1;
        rej_trials(end+1) = idx_nonMidTrigger(i_edge);
        
    else
        
        rej_trials(end+1) = idx_nonMidTrigger(i_edge);
        
    end
    
end


idx_MidTrigger = find(strcmp({EEG.event.code}, midtrialTrigger));
for i_trial = 1 : numel(idx_MidTrigger)
   
    if idx_MidTrigger(i_trial) == 1 || ...
            idx_MidTrigger(i_trial) == numel(EEG.event)
        continue
    end
    
    neighbour_trials = ...
        [idx_MidTrigger(i_trial-1) idx_MidTrigger(i_trial+1)];
    
    if EEG.event(idx_MidTrigger(i_trial)).latency - EEG.times < ...
            EEG.event(min(neighbour_trials)).latency
        
        rej_trials(end+1) = min(neighbour_trials);
        rej_trials(end+1) = idx_MidTrigger(i_trial);
        
    elseif EEG.event(idx_MidTrigger(i_trial)).latency + EEG.times > ...
            EEG.event(max(neighbour_trials)).latency
        
        rej_trials(end+1) = max(neighbour_trials);
        rej_trials(end+1) = idx_MidTrigger(i_trial);
    
    end

end


rej_trials = sort(unique(rej_trials));
if ~isempty(rej_trials)
    [EEG, EEG.lst_changes{end+1,1}] = pop_rejepoch( EEG, rej_trials ,0);
end