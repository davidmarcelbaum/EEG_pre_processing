clc
clear
close all

%% Set up userland

openPath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/MedianFiltered/';

cd (openPath)

eeglab nogui;
EEG             = pop_loadset;

subject = EEG.setname;


savePath = '/home/renate/Documents/Sleep/Data/ModTypes_NotEpoched/';
cd (savePath)


%% Get trigger on and off states
idx_switched_ON     = find(strcmp({EEG.event.code},'DIN1'));
idx_switched_OFF    = find(strcmp({EEG.event.code},'DIN2'));

get_cidx= {EEG.event.mffkey_cidx};

%% Which of the triggers are Placebo and which are Odor
% Based on odds vs even @Jens' mail, INDEPENDANTLY OF ON OR OFF
trigger_placebo        = find(mod(str2double(get_cidx),2)==0);
trigger_odor         = find(mod(str2double(get_cidx),2)~= 0);

%% Get trigger time stamps

idx_placebo_OFF  = intersect(idx_switched_OFF,trigger_placebo);
idx_odor_OFF     = intersect(idx_switched_OFF,trigger_odor);

idx_placebo_ON   = intersect(idx_switched_ON,trigger_placebo);
idx_odor_ON      = intersect(idx_switched_ON,trigger_odor);

%% Change event types and save former types as former_type
for i = 1:size(idx_odor_ON,2)
    
    EEG.event(idx_odor_ON(i)).former_type = EEG.event(idx_odor_ON(i)).type;
    EEG.event(idx_odor_ON(i)).type = '10'; %code for odor_ON
    
end

for i = 1:size(idx_odor_OFF,2)
    
    EEG.event(idx_odor_OFF(i)).former_type = EEG.event(idx_odor_OFF(i)).type;
    EEG.event(idx_odor_OFF(i)).type = '11'; %code for odor_OFF
    
end

for i = 1:size(idx_placebo_ON,2)
    
    EEG.event(idx_placebo_ON(i)).former_type = EEG.event(idx_placebo_ON(i)).type;
    EEG.event(idx_placebo_ON(i)).type = '20'; %code for placebo_ON
    
end

for i = 1:size(idx_placebo_OFF,2)
    
    EEG.event(idx_placebo_OFF(i)).former_type = EEG.event(idx_placebo_OFF(i)).type;
    EEG.event(idx_placebo_OFF(i)).type = '21'; %code for placebo_OFF
    
end

%% Check trigger separation
m = 0;
del_events = [];
for i = 2:size(EEG.event,2)
    if (EEG.event(i).latency - EEG.event(i-1).latency) < 15000
        if m == 0
            display ('The following events have separations closer than 15s')
            m = 1;
        end
        i;
        del_events = [del_events i-1 i];
    end
        
end

if m == 0
    display('All events have adequate separations.')
end

%% Delete events close to each other
if m ~= 0
    display ('Events to delete:')
    del_events
    
    for j = size(del_events,2):-1:1
 
        EEG = pop_editeventvals(EEG,'delete',del_events(j));
        
    end
end

%% Saving here
str_savefile  = strcat(subject, ...
    '_evtype_notepoched', '.set');

pop_saveset( EEG, 'filename', str_savefile, 'filepath', savePath);

