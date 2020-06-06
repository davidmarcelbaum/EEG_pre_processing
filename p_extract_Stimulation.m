
start_pnt       = EEG.event(1).latency-10;
stop_pnt        = EEG.event(end).latency+10;

% Extract data points and latencies from dataset and store in data
% and time vector
v_data   = EEG.data(:,start_pnt:stop_pnt);


% ---------------------------------------------------------------------
% Assign EEGLAB structures to the extracted values

EEG.data            = v_data;
EEG.pnts            = size(EEG.data, 2);
EEG.times           = 1:size(EEG.data, 2); % is continuous

for i = 1:length(EEG.event)
    EEG.event(i).latency   = EEG.event(i).latency - int32(start_pnt);
    EEG.urevent(i).latency = EEG.urevent(i).latency - int32(start_pnt);
end



