eeg_dir = which('eeglab');
addpath(strcat(eeg_dir, filesep, '*'))

% Prompt for loading
EEG = pop_loadset;

for i = 1:numel({EEG.event.label})
	EEG.event(i).type = EEG.event(i).label;
end

EEG_rej             = EEG;
EEG_rej.data        = EEG_rej.rejecteddata;
EEG_rej.chanlocs    = EEG_rej.rejectedchanlocs;
EEG_rej             = eeg_checkset(EEG_rej);
EEG_rej.icawinv     = [];       
EEG_rej.icasphere   = [];
EEG_rej.icaweights  = [];
EEG_rej.icachansind = [];

% Then, epoch data with "DIN2" "-15 15"
EEG = pop_epoch( EEG, ...
    {  'DIN1'  }, ...
    [-15  15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

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

k = 0;
for j = 1:numel({EEG_rej.event.label})
    if strcmp(EEG_rej.event(j).type, 'DIN1')
        k = k+1;
        if k > 9
            EEG_rej.event(j).type = strcat('tr.', num2str(k));
        else
            EEG_rej.event(j).type = strcat('tr.', num2str(0), num2str(k));
        end
    end
end

clear i j k


EEG = pop_resample(EEG, 25); % Faster plotting
EEG_rej = pop_resample(EEG_rej, 25);
EEG_ica = EEG;
EEG_ica.data = eeg_getdatact(EEG, 'component', [1:size(EEG.icaweights,1)]);

% pop_eegbrowser is faster, but EEGBrowser updates first window to fit last one!
% pop_eegbrowser(EEG, 0);
% set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);
% % pop_eegbrowser(EEG2, 0);
% % set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);


% Plot channel measures (without controls)
eegplot('noui', EEG.data, 'srate', EEG.srate, 'winlength', 3, ...
    'events', EEG.event, 'dispchans', EEG.nbchan, ...
    'title', 'CHANNEL MEASURES', 'color', 'off');
set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);

% Plot EOG, EMG, face electrodes
% eegplot('noui', EEG_rej.data, 'srate', EEG_rej.srate, 'winlength', 3, ...
%     'events', EEG.event, 'dispchans', EEG_rej.nbchan, ...
%     'title', 'OTHERS', 'color', 'off', 'children', 1);
% set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 0.4]);

% Plot ICA (only window with controls...
% The first two windows will follow changes of this one here.)
% eegplot(EEG_ica.data, 'srate', EEG_ica.srate, 'winlength', 3, ...
%     'events', EEG_ica.event, 'dispchans', 20, ...
%     'title', 'IC ACTIVITY', 'color', 'off', ...
%     'children', 2);
% set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);

EEGBrowser(EEG_rej, 0);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 0.4]);
eegplot(EEG_ica.data, 'srate', EEG_ica.srate, 'winlength', 3, ...
    'events', EEG_ica.event, 'dispchans', 20, ...
    'title', 'IC ACTIVITY', 'color', 'off', ...
    'children', 1);
set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);

EEG.setname = EEG.datfile;
EEG.setname = strrep(EEG.setname, '.fdt', 'TEMP.set');
eeglab redraw % Necessary for showing dataset in EEGLAB window


