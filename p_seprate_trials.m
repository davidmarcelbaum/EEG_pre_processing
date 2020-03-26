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

%% Set up userland
lst_changes     = {};
eeglab;
EEG             = pop_loadset;

savePath        = strcat(EEG.filepath, 'SepTriggers', filesep);

[EEG, lst_changes{end+1,1}] = pop_epoch( EEG, ...
    { }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

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
EEG_sham    = EEG;
EEG_cue     = EEG;

[EEG_sham, lst_changes_sham]    = ...
    pop_select( EEG_sham, 'trial', idx_mid_trial_sham );
[EEG_cue, lst_changes_cue]     = ...
    pop_select( EEG_cue, 'trial', idx_mid_trial_cue );

if ~isfield(EEG, 'lst_changes')
    EEG.lst_changes = lst_changes;
else
    EEG.lst_changes(...
        numel(EEG.lst_changes) + 1 : ...
        numel(EEG.lst_changes) + numel(lst_changes)) = ...
        lst_changes;
end

EEG_sham.lst_changes            = EEG.lst_changes;
EEG_sham.lst_changes{end+1,1}   = {lst_changes_sham};
EEG_cue.lst_changes             = EEG.lst_changes;
EEG_cue.lst_changes{end+1,1}    = {lst_changes_cue};

%% Saving here
str_savefile_sham  = strcat(extractBefore(EEG.filename, '.set'), ...
    '_Sham_', set_sequence, '.set');
str_savefile_cue  = strcat(extractBefore(EEG.filename, '.set'), ...
    '_Cue_', set_sequence, '.set');

EEG = EEG_sham;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_sham, ...
    'filepath', savePath);

EEG = EEG_cue;
[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile_cue, ...
    'filepath', savePath); % strings to be defined

