eeglab


% Prompt for loading
EEG = pop_loadset;

for i = 1:numel({EEG.event.label})
	EEG.event(i).type = EEG.event(i).label;
end

% Then, epoch data with "DIN1" "-15 15"
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

EEG2 = EEG;
tmpdata = eeg_getdatact(EEG2, 'component', [1:size(EEG.icaweights,1)]);
EEG2.data = tmpdata;

EEG3 = pop_resample(EEG, 100); % Faster plotting

pop_eegbrowser(EEG, 0);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 0.5 1]);
% pop_eegbrowser is faster, but EEGBrowser updates first window to fit last one!
eegplot(EEG3.data, 'srate', EEG.srate, 'winlength', 3, ...
    'events', EEG.event, 'dispchans', 20, 'color', 'off'); %
% pop_eegbrowser(EEG2, 0);
set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);



eeglab redraw % Necessary for showing dataset in EEGLAB window