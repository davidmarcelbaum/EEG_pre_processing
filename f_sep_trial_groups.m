function [EEG_Cue, EEG_Sham, set_sequence] = ...
    f_sep_trial_groups(EEG, savePath)

% |===USER INPUT===|
% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
set_sequence    = 'switchedON_switchedOFF'; 
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").
% |=END USER INPUT=|


[EEG] = pop_epoch( EEG, ...
    { }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

%% Reject epochs with overlapping trials
rej_epochs      =[];

for i = 1:size(EEG.epoch,2)
    if size(EEG.epoch(i).eventduration,2) ~=1
        rej_epochs = [rej_epochs i];
    end
    
end
    
EEG = pop_rejepoch( EEG, rej_epochs ,0);


%% Get trigger on and off states
idx_switched_ON     = find(strcmp({EEG.event.code},'DIN1'));
idx_switched_OFF    = find(strcmp({EEG.event.code},'DIN2'));

get_cidx= {EEG.event.mffkey_cidx};

%% Which of the triggers are Placebo and which are Odor
% Based on odds vs even @Jens' mail, INDEPENDANTLY OF ON OR OFF
trigger_sham        = find(mod(str2double(get_cidx),2)==0);
trigger_cue         = find(mod(str2double(get_cidx),2)~= 0);


%% Get trigger time stamps
if strcmp(set_sequence, 'switchedON_switchedOFF')
    
    idx_mid_trial_sham  = intersect(idx_switched_OFF,trigger_sham);
    idx_mid_trial_cue   = intersect(idx_switched_OFF,trigger_cue);
    
elseif strcmp(set_sequence, 'switchedOFF_switchedON')
    
    idx_mid_trial_sham  = intersect(idx_switched_ON,trigger_sham);
    idx_mid_trial_cue   = intersect(idx_switched_ON,trigger_cue);
    
else
    
    error('Error in "set_sequence" declaration')

end
    
    
%% Isolating trial of interest into separate structures
EEG_Sham    = EEG;
EEG_Cue     = EEG;

[EEG_Sham, lst_changes_sham]    = ...
    pop_select( EEG_Sham, 'trial', idx_mid_trial_sham );
[EEG_Cue, lst_changes_cue]     = ...
    pop_select( EEG_Cue, 'trial', idx_mid_trial_cue );


EEG_Sham.lst_changes{end+1,1}   = lst_changes_sham;
EEG_Cue.lst_changes{end+1,1}    = lst_changes_cue;

end

