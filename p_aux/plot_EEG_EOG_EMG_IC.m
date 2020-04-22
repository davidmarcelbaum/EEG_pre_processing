dataFile = 'RC_091_sleep_ICAweights.set';
dataPath = '/home/sleep/Desktop/DavidExploringFilterDesigns/preProcessing/ICAweights';

% Prompt for loading
eeglab
EEG = pop_loadset('filename', dataFile, 'filepath', dataPath);

for i = 1:numel({EEG.event.label})
	EEG.event(i).type = EEG.event(i).label;
end

EEG_rej = EEG;
EEG_rej.data = EEG_rej.rejecteddata;
EEG_rej.nbchan = numel(EEG.rejectedchanlocs);

% Then, epoch data with "DIN1" (off) "-15 15"
EEG = pop_epoch( EEG, ...
    {  'DIN1'  }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

% Then, epoch data with "DIN1" (off) "-15 15"
EEG_rej = pop_epoch( EEG_rej, ...
    {  'DIN1'  }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

% Then for conveniance of parallel EEG browsing, change trial codes
k = 0;
for j = 1:numel({EEG.event.label})
    if strcmp(EEG.event(j).type, 'DIN1')
        k = k+1;
        if k > 9
            EEG.event(j).type = strcat('tr.', num2str(k));
        else
            EEG.event(j).type = strcat('tr.', num2str(0), num2str(k));
        end
    end
end

clear i j k


EEG_ica = EEG;
EEG_ica.data = eeg_getdatact(EEG_ica, 'component', [1:size(EEG.icaweights,1)]);

% For faster plotting
EEG     = pop_resample(EEG, 50);
EEG_rej = pop_resample(EEG_rej, 50);
EEG_ica.nbchan = size(EEG_ica.data,1);
EEG_ica = pop_resample(EEG_ica, 50);


% pop_eegbrowser is faster, but EEGBrowser extracts data time serie for
% every window you change to an therefore will display the last data that
% has been loaded.
pop_eegbrowser(EEG, 0);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);

% Plot channel measures (without controls)
% eegplot('noui', EEG.data, 'srate', EEG.srate, 'winlength', 3, ...
%     'events', EEG.event, 'dispchans', EEG.nbchan, ...
%     'title', 'CHANNEL MEASURES', 'color', 'off');
% set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);

% Plot ICA (only window with controls...
% The first two windows will follow changes of this one here.)
eegplot(EEG_ica.data, 'srate', EEG_ica.srate, 'winlength', 3, ...
    'events', EEG.event, 'dispchans', 20, ...
    'title', 'IC ACTIVITY', 'color', 'off');
set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);

eegplot(EEG_rej.data, 'srate', EEG_rej.srate, 'winlength', 3, ...
    'events', EEG.event, 'dispchans', EEG_rej.nbchan, ...
    'title', 'EOG, EMG, ...', 'color', 'off');
set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);

% Some parts again in order to plot IC labels
EEG = pop_loadset('filename', dataFile, 'filepath', dataPath);

for i = 1:numel({EEG.event.label})
	EEG.event(i).type = EEG.event(i).label;
end

% Then, epoch data with "DIN1" (off) "-15 15"
EEG = pop_epoch( EEG, ...
    {  'DIN1'  }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

% Then for conveniance of parallel EEG browsing, change trial codes
k = 0;
for j = 1:numel({EEG.event.label})
    if strcmp(EEG.event(j).type, 'DIN1')
        k = k+1;
        if k > 9
            EEG.event(j).type = strcat('tr.', num2str(k));
        else
            EEG.event(j).type = strcat('tr.', num2str(0), num2str(k));
        end
    end
end

clear i j k

EEG.setname = EEG.datfile;
EEG.setname = strrep(EEG.setname, '.fdt', 'TEMP.set');
eeglab redraw % Necessary for showing dataset in EEGLAB window
