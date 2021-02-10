function [EEG_Odor, EEG_Sham, set_sequence] = f_sep_trial_groups(...
    EEG, set_sequence, noiseTrialFile, def_variable)

% |===USER INPUT===|
trialEdges = [-15 15]; %Default [-15 15];
% Default [-15 15]. What are the edges (s) around the event codes which the
% trials should be extracted of.
% |=END USER INPUT=|

% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
% set_sequence    = cell string of sequence of odor stimulation and
%                   olfactometer control
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

% noiseTrialFile    = string of path to the .mat file that contains
% information about trials/epochs to be rejected. The file should be
% organized in 3 columns:
% Col 1 = cell strings of subjects where the string is equal to "str_base"
% Col 2 = array of independent components to reject. Not needed for this
%         function
% Col 3 = array of epochs to reject
% The matrix should be contained in a variable whose name is defined by
% "def_variable"
% Leave both EMPTY if you don't want to reject epochs based on this method

global str_base

% At this stage, the rejecteddata field (containing time series of rejected
% channels) is probably not of any need any more and increases the file 
% size unnecessarily.
EEG = rmfield(EEG, 'rejecteddata');



%% Retain only trials with selected midtrial trigger type
if strcmp(set_sequence, 'ON_OFF')
    triggerOI   = 'DIN2';
    triggerEND  = 'DIN1';
elseif strcmp(set_sequence, 'OFF_ON')
    triggerOI   = 'DIN1';
    triggerEND  = 'DIN2';
end

idx_triggerOI   = find(strcmp({EEG.event.label}, triggerOI));


cidx_all                                = {EEG.event.mffkey_cidx};
cidx_all(cellfun('isempty',cidx_all))   = [];
cidx_all                                = cellfun(@str2double,cidx_all);
cidx_unique                             = sort(unique(cidx_all));

for cidx = numel(cidx_unique):-1:1
    
    will_be_rejected = 0;
    
    idx = find(strcmp({EEG.event.mffkey_cidx}, ...
        num2str(cidx_unique(cidx))));
    % where in the event structure are we
    
    % For each event, check whether it occurs exactly twice (start/end)
    if sum(cidx_all == cidx_unique(cidx)) ~= 2
        will_be_rejected = 1;
        warning(['Deleting stimulation because it doesnt have a s', ...
            'tart and end.'])
        
        % ...whether first is a start and second an end trigger
    elseif ~strcmp(EEG.event(idx(1)).label, 'DIN1') || ...
            ~strcmp(EEG.event(idx(2)).label, 'DIN2')
        will_be_rejected = 1;
        warning(['Deleting stimulation because it doesnt have the r', ...
            'ight start and end.'])
        
        % ...whether it is about 15 s long
    elseif EEG.event(idx(2)).latency - EEG.event(idx(1)).latency ...
            < 15 * EEG.srate || ...
            EEG.event(idx(2)).latency - EEG.event(idx(1)).latency ...
            > 15.1 * EEG.srate
        will_be_rejected = 1;
        warning('Deleting stimulation because its too short or too long.')
        
    end
    
    if will_be_rejected == 0
        % Avoid diving into this since the following section is assuming
        % that idx is a two-element vector which the first if statement
        % above might already have been checking
        
        % A complete cycle is defined as Odor On and Off followed by
        % Sham On and Off. Here we reject Odor and Sham conditions that 
        % stand alone
        if mod(cidx_unique(cidx),2) ~= 0 && idx(2) < length(EEG.event)
            % Odor condition (odd mffkey_cidx): We check whether the 
            % condition afterwards is a vehicle one
            idx_next    = idx + 2;
            % Reject the second idx_next if last condition was a sham On 
            % one without Off period which is ok for us
            idx_next(idx_next > length(EEG.event)) = [];
            
            cidx_next   = str2double({EEG.event(idx_next).mffkey_cidx});
            if any(mod(cidx_next, 2) ~= 0) || ...
                    any(isempty(cidx_next)) || ...
                    any(isnan(cidx_next))% Sham conditions are pair values
                will_be_rejected = 1;
                warning(['Deleting Odor condition since it is no', ...
                    't followed by Sham'])
            end
        end
        
        if mod(cidx_unique(cidx),2) == 0 && idx(1) > 2
            % Odor condition (pair mffkey_cidx): We check whether the 
            % condition before is a odor one
            idx_before  = idx - 2;
            
            cidx_before = str2double({EEG.event(idx_before).mffkey_cidx});
            if any(mod(cidx_before, 2) == 0) || ...
                    any(isempty(cidx_before)) || ...
                    any(isnan(cidx_before)) % Odor conditions are odd values
                will_be_rejected = 1;
                warning(['Deleting Sham condition since it is no', ...
                    't preseded by Odor'])
            end
        end
        
    end
    
    if will_be_rejected == 1
        cidx
        cidx_unique(cidx) = [];
    end
    
end


% Now all EEG.event are valid, all odd ones are odor, all even ones are
% sham
cidx_odor       = cidx_unique(mod(cidx_unique,2) ~= 0);
cidx_sham       = cidx_unique(mod(cidx_unique,2) == 0);

[~,Odor_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_odor);
[~,Sham_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_sham);

idx_trigger_odor          = intersect(idx_triggerOI, Odor_Epochs);
idx_trigger_sham          = intersect(idx_triggerOI, Sham_Epochs);


EEG_Sham        = EEG;
EEG_Odor        = EEG;

[EEG_Sham, EEG_Sham.lst_changes{end+1,1}] = pop_epoch( EEG_Sham, ...
    {EEG_Sham.event(idx_trigger_sham).type}, ...
    trialEdges, ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');
[EEG_Odor, EEG_Odor.lst_changes{end+1,1}] = pop_epoch( EEG_Odor, ...
    {EEG_Odor.event(idx_trigger_odor).type}, ...
    trialEdges, ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');


end

% 
% 
% 
% [EEG, EEG.lst_changes{end+1,1}] = pop_epoch( EEG, ...
%     { }, ...
%     trialEdges, ...
%     'newname', 'temp_set', ...
%     'epochinfo', 'yes');
% 
% 
% 
% 
% % This here is needed because EEG.epoch structure holds either cells or
% % chars for EEG.epoch.eventlabel (and others) based on whether at least one
% % trial contains overlapping triggers or not
% for i_trans = 1 : numel(EEG.epoch)
%     if numel(EEG.epoch(i_trans).event) == 1
%         EEG.epoch(i_trans).eventlabel = char(EEG.epoch(i_trans).eventlabel);
%         EEG.epoch(i_trans).eventtype = char(EEG.epoch(i_trans).eventtype);
% %         eventduration
% %         eventrelativebegintime
% %         eventsourcedevice
% %         eventlatency
%     end
% end
% 
% % -------------------------------------------------------------------------
% % Identify trials that only contain one trigger (that is they are not
% % overlapping with other trials) and only the trigger of interest
% % (triggerOI) as midpoint of epoch
% idx_triggerOI           = find(strcmp({EEG.epoch.eventlabel}, triggerOI));
% idx_unique_triggers     = [];
% for i = 1:size(EEG.epoch,2)
%     if numel(EEG.epoch(i).event) == 1
%         idx_unique_triggers = [idx_unique_triggers i];
%     end
% end
% 
% 
% % *************************************************************************
% % (Addition 1 here)
% % *************************************************************************
% 
% 
% idx_trialsOI = intersect(idx_triggerOI, idx_unique_triggers);
% 
% % -------------------------------------------------------------------------
% % Slice the dataset again in only epochs of interest
% [EEG, EEG.lst_changes{end+1,1}] = pop_epoch( EEG, ...
%     { EEG.epoch(idx_trialsOI).eventtype }, ...
%     trialEdges, ...
%     'newname', 'temp_set', ...
%     'epochinfo', 'yes');
% 
% 
% % *************************************************************************
% % (Addition 2 here)
% % *************************************************************************
% 
% 
% %% Reject trials that have been labeled for rejection in a separate file
% 
% if ~isempty(noiseTrialFile) && ~isempty(def_variable)
%     % ---------------------------------------------------------------------
%     % Extract the vectors of the noisy periods that are given by the
%     % sideloaded file
%     noisyTrials = load(noiseTrialFile);
%     
%     subj_row = find(strcmp(noisyTrials.(def_variable)(:,1), ...
%         str_base));
%     
%     rej_trials = noisyTrials.(def_variable){subj_row,3};
%     
%     % ---------------------------------------------------------------------
%     % Simply reject the epochs
%     if ~isempty(rej_trials)
%         [EEG, EEG.lst_changes{end+1,1}] = ...
%             pop_rejepoch( EEG, rej_trials ,0);
%     end
% 
% end
% 
% 
% %% Determine groups of trials and separate them
% get_cidx= {EEG.event.mffkey_cidx};
% 
% % Based on odds vs even @Jens' mail, INDEPENDANTLY OF ON OR OFF
% idx_trigger_sham        = find( mod(str2double(get_cidx), 2) == 0);
% idx_trigger_odor        = find( mod(str2double(get_cidx), 2) ~= 0);
% 
% % Here we reject the last trial if it is not complete (which means,
% % recording stopped before trial fully finished). The partial trial will
% % be removed from EEG.data and EEG.epoch but will still be shown in 
% % EEG.event, which is what we use to identify trials.
% if size(EEG.data, 3) ~= length(EEG.epoch)
%     error('Incompatible epoch handling')
% end
% s_rej = 0;
% if idx_trigger_sham(end) > size(EEG.data, 3)
%     idx_trigger_sham = idx_trigger_sham(1:end-1);
%     s_rej = s_rej + 1;
% end
% if idx_trigger_odor(end) > size(EEG.data, 3)
%     idx_trigger_odor = idx_trigger_odor(1:end-1);
%     s_rej = s_rej + 1;
% end
% if s_rej > 1
%     error('More than one incomplete trials. This does not make sense')
% end
%     
% % -------------------------------------------------------------------------
% % Isolating trial of interest into separate structures
% 
% EEG_Sham    = EEG;
% EEG_Odor    = EEG;
% 
% [EEG_Sham, EEG_Sham.lst_changes{end+1,1}]    = ...
%     pop_select( EEG_Sham, 'trial', idx_trigger_sham );
% [EEG_Odor, EEG_Odor.lst_changes{end+1,1}]     = ...
%     pop_select( EEG_Odor, 'trial', idx_trigger_odor );
% 
% 
% end
% 
% 
% %                               Addition 1
% % % =========================================================================
% % %                   For epoching outside of trial borders
% % c_events = {EEG.epoch.eventlabel};
% % c_out = cell(numel(c_events), max(cellfun(@numel, c_events)));
% % for i_c = 1:numel(c_events)
% %     if iscell(c_events{i_c})
% %         c_out(i_c, 1:numel(c_events{i_c})) = c_events{i_c};
% %     else % only one element stored as char
% %         c_out(i_c, 1) = c_events(i_c);
% %     end
% % end
% % idx_triggerOI           = find(strcmp(c_out(:,1), triggerOI));
% % idx_unique_triggers     = [];
% % for i = 1:size(EEG.epoch,2)
% %     if numel(EEG.epoch(i).event) <= 2 && ~strcmp(c_out(i,1), c_out(i,2))
% %         idx_unique_triggers = [idx_unique_triggers i];
% %     end
% %     
% %     if iscell(EEG.epoch(i).eventtype)
% %         EEG.epoch(i).eventtype = EEG.epoch(i).eventtype{1};
% %     else
% %         EEG.epoch(i).eventtype = EEG.epoch(i).eventtype(1);
% %     end
% % end
% 
% % =========================================================================
% 
% 
% 
% %                               Addition 2
% % % =========================================================================
% % %                   For epoching outside of trial borders
% % idx_ev_retain = [];
% % i_add = 0;
% % for i_ev = 1:length(EEG.event)
% %     if mod(i_ev, 2) ~= 0
% %         i_add = i_add + 1;
% %         idx_ev_retain(i_add) = i_ev;
% %     end
% % end
% % EEG.event = EEG.event(idx_ev_retain);
% % % =========================================================================
