clc
clear
close all

%% Set up userland
lst_changes     = {};

openPath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/MedianFiltered/';

cd (openPath)

eeglab;
EEG             = pop_loadset;

subject = EEG.setname;


savePath = '/home/renate/Documents/Sleep/Data/SepTriggers/';
cd (savePath)

[EEG, lst_changes{end+1,1}] = pop_epoch( EEG, ...
    { }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

%% Reject epochs with overlapping trials
rej_epochs      =[];
%HHH=EEG;

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
trigger_placebo        = find(mod(str2double(get_cidx),2)==0);
trigger_odor         = find(mod(str2double(get_cidx),2)~= 0);

%% Variables for handling output
% IMPORTANT:
% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
set_sequence    = 'switchedON_switchedOFF'; 
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

%% Get trigger time stamps
if strcmp(set_sequence, 'switchedON_switchedOFF')
    
    idx_mid_trial_placebo  = intersect(idx_switched_OFF,trigger_placebo);
    idx_mid_trial_odor   = intersect(idx_switched_OFF,trigger_odor);
    
elseif strcmp(set_sequence, 'switchedOFF_switchedON')
    
    idx_mid_trial_placebo  = intersect(idx_switched_ON,trigger_placebo);
    idx_mid_trial_odor   = intersect(idx_switched_ON,trigger_odor);
    
else
    
    error('Error in "set_sequence" declaration')

end
    
    
%% Isolating trial of interest into separate structures
EEE          = EEG;
EEG_placebo  = EEG;
EEG_odor     = EEG;

[EEG_placebo, lst_changes_placebo]    = ...
    pop_select( EEG_placebo, 'trial', idx_mid_trial_placebo );
[EEG_odor, lst_changes_odor]     = ...
    pop_select( EEG_odor, 'trial', idx_mid_trial_odor );

if ~isfield(EEG, 'lst_changes')
    EEG.lst_changes = lst_changes;
else
    EEG.lst_changes(...
        numel(EEG.lst_changes) + 1 : ...
        numel(EEG.lst_changes) + numel(lst_changes)) = ...
        lst_changes;
end

EEG_placebo.lst_changes            = EEG.lst_changes;
EEG_placebo.lst_changes{end+1,1}   = {lst_changes_placebo};
EEG_odor.lst_changes             = EEG.lst_changes;
EEG_odor.lst_changes{end+1,1}    = {lst_changes_odor};

%% Saving here
str_savefile_placebo  = strcat(subject, ...
    '_Sham_', set_sequence, '.set');
str_savefile_odor  = strcat(subject, ...
    '_Cue_', set_sequence, '.set');

EEG = EEG_placebo;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_placebo, ...
    'filepath', savePath);

EEG = EEG_odor;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_odor, ...
    'filepath', savePath); % strings to be defined

%% Variables for handling output
EEG = EEE;
% IMPORTANT:
% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
set_sequence    = 'switchedOFF_switchedON'; 
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

%% Get trigger time stamps
if strcmp(set_sequence, 'switchedON_switchedOFF')
    
    idx_mid_trial_placebo  = intersect(idx_switched_OFF,trigger_placebo);
    idx_mid_trial_odor   = intersect(idx_switched_OFF,trigger_odor);
    
elseif strcmp(set_sequence, 'switchedOFF_switchedON')
    
    idx_mid_trial_placebo  = intersect(idx_switched_ON,trigger_placebo);
    idx_mid_trial_odor   = intersect(idx_switched_ON,trigger_odor);
    
else
    
    error('Error in "set_sequence" declaration')

end
    
    
%% Isolating trial of interest into separate structures
EEG_placebo  = EEG;
EEG_odor     = EEG;

[EEG_placebo, lst_changes_placebo]    = ...
    pop_select( EEG_placebo, 'trial', idx_mid_trial_placebo );
[EEG_odor, lst_changes_odor]     = ...
    pop_select( EEG_odor, 'trial', idx_mid_trial_odor );

if ~isfield(EEG, 'lst_changes')
    EEG.lst_changes = lst_changes;
else
    EEG.lst_changes(...
        numel(EEG.lst_changes) + 1 : ...
        numel(EEG.lst_changes) + numel(lst_changes)) = ...
        lst_changes;
end

EEG_placebo.lst_changes            = EEG.lst_changes;
EEG_placebo.lst_changes{end+1,1}   = {lst_changes_placebo};
EEG_odor.lst_changes             = EEG.lst_changes;
EEG_odor.lst_changes{end+1,1}    = {lst_changes_odor};

%% Saving here
str_savefile_placebo  = strcat(subject, ...
    '_Sham_', set_sequence, '.set');
str_savefile_odor  = strcat(subject, ...
    '_Cue_', set_sequence, '.set');

EEG = EEG_placebo;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_placebo, ...
    'filepath', savePath);

EEG = EEG_odor;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_odor, ...
    'filepath', savePath); % strings to be defined