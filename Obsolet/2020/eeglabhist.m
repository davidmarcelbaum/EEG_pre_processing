% EEGLAB history file generated on the 26-Mar-2020
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','RC_051_sleep_ICAweights.set','filepath','/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/ICAweights/');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
EEG = pop_epoch( EEG, {  }, [-15  15], 'newname', 'RC_051_sleep epochs', 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
EEG = eeg_checkset( EEG );
eeglab redraw;
