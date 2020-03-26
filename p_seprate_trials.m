eeglab;
EEG = pop_loadset;
lst_changes = {};

savePath= cd;
str_savefile = 'heythere.set';
str_savefile2 = 'heyagain.set';

[EEG, lst_changes{end+1,1}] = pop_epoch( EEG, ...
    { }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes'); % or DIN2 for Off-On organization
EEG2 = EEG;

All_DIN1 = find(strcmp({EEG.event.code},'DIN1'));
All_DIN2 = find(strcmp({EEG.event.code},'DIN2'));

get_cidx= {EEG.event.mffkey_cidx};

Placebo_Epochs = find(mod(str2double(get_cidx),2)==0); % Based on odds vs even @Jens' mail
Odor_Epochs = find(mod(str2double(get_cidx),2)~= 0);

[PlaceboOn] = intersect(All_DIN1,Placebo_Epochs);
[PlaceboOff] = intersect(All_DIN2,Placebo_Epochs);

[OdorOn] = intersect(All_DIN1,Odor_Epochs);
[OdorOff] = intersect(All_DIN2,Odor_Epochs);

[EEG, lst_changes{end+1,1}] = pop_select( EEG, 'trial', PlaceboOn ); % 15s Off - 15s On

[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile, ...
    'filepath', savePath); % strings to be defined

% ------
EEG = EEG2;

[EEG, lst_changes{end+1,1}] = pop_select( EEG, 'trial', OdorOn ); % 15s Off - 15s On

[EEG, lst_changes{end+1,1}] = pop_saveset( EEG, ...
    'filename', str_savefile2, ...
    'filepath', savePath); % strings to be defined