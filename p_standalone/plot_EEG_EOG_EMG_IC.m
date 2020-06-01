%% Userland setup
dataFile = 'RC_201_sleep_ICAweights.set';
dataPath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/ICAweightsCustomKaiserwin';
midtrialTrigger = 'DIN2';


%% Automatic part
close all

% Prompt for loading
eeglab
EEG = pop_loadset('filename', dataFile, 'filepath', dataPath);


[EEG, EEG.lst_changes{end+1,1}] = pop_epoch( EEG, ...
    { }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');


for i_trans = 1 : numel(EEG.epoch)
    if numel(EEG.epoch(i_trans).event) == 1
        EEG.epoch(i_trans).eventlabel = char(EEG.epoch(i_trans).eventlabel);
        EEG.epoch(i_trans).eventtype = char(EEG.epoch(i_trans).eventtype);
%         eventduration
%         eventrelativebegintime
%         eventsourcedevice
%         eventlatency
    end
end


idx_triggerOI           = find(strcmp({EEG.epoch.eventlabel}, ...
    midtrialTrigger));


idx_unique_triggers     = zeros(1,size(EEG.epoch,2));
for i = 1:size(EEG.epoch,2)
    if numel(EEG.epoch(i).event) == 1
        idx_unique_triggers(i) = 1;
    end
end
idx_unique_triggers = find(idx_unique_triggers == 1);

idx_trialsOI = intersect(idx_triggerOI, idx_unique_triggers);


% -------------------------------------------------------------------------
% Slice the dataset again in only epochs of interest

% EEG_rej = EEG;
% EEG_rej.data = EEG_rej.rejecteddata;
% EEG_rej.nbchan = numel(EEG.rejectedchanlocs);


[EEG] = pop_epoch( EEG, ...
    { EEG.epoch(idx_trialsOI).eventtype }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');


% [EEG_rej] = pop_epoch( EEG_rej, ...
%     { EEG_rej.epoch(idx_trialsOI).eventtype }, ...
%     [-15 15], ...
%     'newname', 'temp_set', ...
%     'epochinfo', 'yes');

% Then for conveniance of parallel EEG browsing, change trial codes
k = 0;
for j = 1:numel({EEG.event.label})
    k = k+1;
    if k > 9
        EEG.epoch(j).eventtype = strcat('tr.', num2str(k));
        EEG.event(j).type = strcat('tr.', num2str(k));
    else
        EEG.epoch(j).eventtype = strcat('tr.', num2str(0), num2str(k));
        EEG.event(j).type = strcat('tr.', num2str(0), num2str(k));
    end
end

clear i j k


EEG_ica = EEG;
EEG_ica.data = eeg_getdatact(EEG_ica, 'component', [1:size(EEG.icaweights,1)]);

% For faster plotting
% EEG    = pop_resample(EEG, 50);
% EEG_rej = pop_resample(EEG_rej, 50);
EEG_ica.nbchan  = size(EEG_ica.data,1);
EEG_ica         = pop_resample(EEG_ica, 50);


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

% eegplot(EEG_rej.data, 'srate', EEG_rej.srate, 'winlength', 3, ...
%     'events', EEG.event, 'dispchans', EEG_rej.nbchan, ...
%     'title', 'EOG, EMG, ...', 'color', 'off');
% set(gcf, 'units', 'normalized', 'outerposition', [0.5 0 0.5 1]);

% % Some parts again in order to plot IC labels
% EEG = pop_loadset('filename', dataFile, 'filepath', dataPath);
% 
% for i = 1:numel({EEG.event.label})
% 	EEG.event(i).type = EEG.event(i).label;
% end

% % Then, epoch data with "DIN1" (off) "-15 15"
% EEG = pop_epoch( EEG, ...
%     {  midtrialTrigger  }, ...
%     [-15  15], ...
%     'newname', 'temp_set', ...
%     'epochinfo', 'yes');

% % Then for conveniance of parallel EEG browsing, change trial codes
% k = 0;
% for j = 1:numel({EEG.event.label})
%     if strcmp(EEG.event(j).type, midtrialTrigger )
%         k = k+1;
%         if k > 9
%             EEG.event(j).type = strcat('tr.', num2str(k));
%         else
%             EEG.event(j).type = strcat('tr.', num2str(0), num2str(k));
%         end
%     end
% end
% 
% clear i j k

% EEG.setname = EEG.datfile;
% EEG.setname = strrep(EEG.setname, '.fdt', 'TEMP.set');
eeglab redraw % Necessary for showing dataset in EEGLAB window
