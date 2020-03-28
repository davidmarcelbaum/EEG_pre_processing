% Adaptations to do

% Epoch EEG.rejecteddata and append these channels before ICA activities
% with channel labels and different color. This way, EOG/EMG and ICA in the
% same window
[EEG.rejecteddata; EEG.icaact]
[EEG.rejectedchanlocs; EEG.chanlocs]


% Prompt for loading
eeglab
EEG = pop_loadset;

for i = 1:numel({EEG.event.label})
	EEG.event(i).type = EEG.event(i).label;
end

% Then, epoch data with "DIN2" "-15 15"
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


EEG = pop_resample(EEG, 50); % Faster plotting
EEG_rej = pop_resample(EEG_rej, 50);
EEG_ica = EEG;
EEG_ica.data = eeg_getdatact(EEG, 'component', [1:size(EEG.icaweights,1)]);

% pop_eegbrowser is faster, but EEGBrowser updates first window to fit last one!
pop_eegbrowser(EEG, 0);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);
% % pop_eegbrowser(EEG2, 0);
% % set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);


% Plot channel measures (without controls)
% eegplot('noui', EEG.data, 'srate', EEG.srate, 'winlength', 3, ...
%     'events', EEG.event, 'dispchans', EEG.nbchan, ...
%     'title', 'CHANNEL MEASURES', 'color', 'off');
% set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);

% Plot ICA (only window with controls...
% The first two windows will follow changes of this one here.)
eegplot(EEG_ica.data, 'srate', EEG_ica.srate, 'winlength', 3, ...
    'events', EEG_ica.event, 'dispchans', 20, ...
    'title', 'IC ACTIVITY', 'color', 'off');
set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);


EEG.setname = EEG.datfile;
EEG.setname = strrep(EEG.setname, '.fdt', 'TEMP.set');
eeglab redraw % Necessary for showing dataset in EEGLAB window


