%% Set up userland
eeglab;
EEG = pop_loadset;
lst_changes = {};

%% Variables for handling output
savePath= cd;
str_savefile = 'heythere.set';
str_savefile2 = 'heyagain.set';

%% Slicing dataset into epochs (all)
[EEG, lst_changes{end+1,1}] = pop_epoch( EEG, ...
    { }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');
EEG2 = EEG;

%% Get trigger on and off states
All_DIN1 = find(strcmp({EEG.event.code},'DIN1'));
All_DIN2 = find(strcmp({EEG.event.code},'DIN2'));

get_cidx= {EEG.event.mffkey_cidx};

%% Which of the triggers are Placebo and which are Odor
% Based on odds vs even @Jens' mail
Placebo_Epochs = find(mod(str2double(get_cidx),2)==0);
Odor_Epochs = find(mod(str2double(get_cidx),2)~= 0);

%% Get trigger time stamps
% IMPORTANT:
% TriggerOn means that trials are [15s pre-Trigger, 15s ongoing Trigger]
% TriggerOff means that trials are [15s ongoing Trigger, 15s post-Trigger]
% The trigger events here are "switching ON the trigger" and "switching OFF
% the trigger" for TriggerOn and TiggerOff, respectively.

[PlaceboOn] = intersect(All_DIN1,Placebo_Epochs);
[PlaceboOff] = intersect(All_DIN2,Placebo_Epochs);

[OdorOn] = intersect(All_DIN1,Odor_Epochs);
[OdorOff] = intersect(All_DIN2,Odor_Epochs);

%% Reject everything that is NOT related to Placebo
[EEG, lst_changes{end+1,1}] = pop_select( EEG, 'trial', PlaceboOn );

[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile, ...
    'filepath', savePath); % strings to be defined

% ------
EEG = EEG2;

%% Reject everything that is NOT related to Odor
[EEG, lst_changes{end+1,1}] = pop_select( EEG, 'trial', OdorOn );

[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile2, ...
    'filepath', savePath); % strings to be defined