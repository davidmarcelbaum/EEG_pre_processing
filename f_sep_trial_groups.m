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
if isfield(EEG, 'rejecteddata')
    EEG = rmfield(EEG, 'rejecteddata');
end



%%  Retain only trials with selected midtrial trigger type of valid length

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

cidx_unique_ori = cidx_unique;

for cidx = numel(cidx_unique):-1:1
    
    will_be_rejected        = 0;
    
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
            ~strcmp(EEG.event(idx(end)).label, 'DIN2')
        will_be_rejected = 1;
        warning(['Deleting stimulation because it doesnt have the r', ...
            'ight start and end.'])
        
        % ...whether the On period is about 15 s long
    elseif EEG.event(idx(end)).latency - EEG.event(idx(1)).latency ...
            < 15 * EEG.srate || ...
            EEG.event(idx(end)).latency - EEG.event(idx(1)).latency ...
            > 15.1 * EEG.srate
        will_be_rejected = 1;
        warning('Deleting stimulation because its too short or too long.')
       
    end
    
    % Check whether condition is too close to subsequent one
    remove_subseq = 0;
    
    if cidx_unique(cidx) == cidx_unique_ori(end) && ...
            mod(cidx_unique(cidx), 2) ~= 0
        will_be_rejected = 1; % Since no Sham condition following
        warning('Deleting Odor because not followed by Sham')
    elseif idx(end) < length(EEG.event) - 2
        
        if cidx_unique(cidx) == cidx_unique(end)
            break
        end
        idx_subseq = find(strcmp({EEG.event.mffkey_cidx}, ...
            num2str(cidx_unique(cidx+1))));
        
        if mod(cidx_unique(cidx), 2) ~= 0 && ( ...
                EEG.event(idx_subseq(1)).latency - ...
                EEG.event(idx(end)).latency < 15 * EEG.srate || ...
                EEG.event(idx_subseq(1)).latency - ...
                EEG.event(idx(end)).latency > 15.1 * EEG.srate )
            % We care here whether Odor condition is of adequate length to
            % the next Sham condition
            remove_subseq = 1;
            will_be_rejected = 1;
        elseif mod(cidx_unique(cidx), 2) == 0 && ( ...
                EEG.event(idx_subseq(1)).latency - ...
                EEG.event(idx(end)).latency < 15 * EEG.srate )
            % We don't care whether the next trial is too far away since
            % it's Sham here and therefore the end of the stimulation cycle
            remove_subseq = 1;
            will_be_rejected = 1;
        end
    end
    
    if remove_subseq == 1
        cidx_unique(cidx+1)
        cidx_unique(cidx+1) = [];
    end
    
    if will_be_rejected == 1
        cidx_unique(cidx)
        cidx_unique(cidx) = [];
    end
    
end


% It can occur that because of sleep scoring an Odor condition is not
% listed in the EEG.event structure as first condition since it has been
% rejected by extractsws, but instead the structure is starting by Sham. We
% correct this here.
if mod(cidx_unique(1), 2) == 0 % Sham condition
    cidx_unique(1) = [];
end



%% =-=-=-=-=-=-=-=-=-=- Slice datasets into trials -=-=-=-=-=-=-=-=-=-=-=-=

% Now all EEG.event are valid, all odd ones are odor, all even ones are
% sham
cidx_odor       = cidx_unique(mod(cidx_unique,2) ~= 0);
cidx_sham       = cidx_unique(mod(cidx_unique,2) == 0);

[~,Odor_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_odor);
[~,Sham_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_sham);

idx_trigger_odor          = intersect(idx_triggerOI, Odor_Epochs);
idx_trigger_sham          = intersect(idx_triggerOI, Sham_Epochs);


% % End check-up
% if numel(idx_trigger_odor) ~= numel(idx_trigger_sham) || ...
%         mod(cidx_unique(end), 2) ~= 0
%    error('Still not matching correctly!') 
% end


EEG_Sham        = EEG;
EEG_Odor        = EEG;

[EEG_Sham, EEG_Sham.lst_changes{end+1,1}] = pop_epoch( EEG_Sham, ...
    {EEG_Sham.event(idx_trigger_sham).type}, ...
    trialEdges, ...
    'newname', str_base, ...
    'epochinfo', 'yes');
[EEG_Odor, EEG_Odor.lst_changes{end+1,1}] = pop_epoch( EEG_Odor, ...
    {EEG_Odor.event(idx_trigger_odor).type}, ...
    trialEdges, ...
    'newname', str_base, ...
    'epochinfo', 'yes');



%% =-=-=-=-=-=-=-=-=-=- Balance sequence of trials -=-=-=-=-=-=-=-=-=-=-=-=

% Check for overlapping conditions

cidx_sham = {EEG_Sham.event.mffkey_cidx};
cidx_sham = cellfun(@str2double,cidx_sham);

cidx_odor = {EEG_Odor.event.mffkey_cidx};
cidx_odor = cellfun(@str2double,cidx_odor);

% Check Odor conditions
idx_remove = [];
idx_incomp = find(mod(cidx_odor, 2) == 0);
idx_multip = [];
for i_num = 1:numel(cidx_odor)
    s_found = find(cidx_odor == cidx_odor(i_num));
    if numel(s_found) > 1
        idx_multip = [idx_multip, i_num];
    end
end

idx_check = [idx_incomp, idx_multip];
for i = 1:numel(idx_check)
    if EEG_Odor.event(idx_check(i)+1).latency - ...
            EEG_Odor.event(idx_check(i)).latency < 15 * EEG.srate
        idx_remove = [idx_remove, idx_check(i), idx_check(i) + 1];
    end
    if EEG_Odor.event(idx_check(i)).latency - ...
            EEG_Odor.event(idx_check(i)-1).latency < 15 * EEG.srate
        idx_remove = [idx_remove, idx_check(i), idx_check(i) - 1];
    end
end
idx_remove_odor = unique(idx_remove);

cidx_odor(idx_remove_odor) = [];



% Check Sham conditions
idx_remove = [];
idx_incomp = find(mod(cidx_sham, 2) ~= 0);
idx_multip = [];
for i_num = 1:numel(cidx_sham)
    s_found = find(cidx_sham == cidx_sham(i_num));
    if numel(s_found) > 1
        idx_multip = [idx_multip, i_num];
    end
end

idx_check = [idx_incomp, idx_multip];
for i = 1:numel(idx_check)
    if EEG_Sham.event(idx_check(i)+1).latency - ...
            EEG_Sham.event(idx_check(i)).latency < 15 * EEG.srate
        idx_remove = [idx_remove, idx_check(i), idx_check(i) + 1];
    end
    if EEG_Sham.event(idx_check(i)).latency - ...
            EEG_Sham.event(idx_check(i)-1).latency < 15 * EEG.srate
        idx_remove = [idx_remove, idx_check(i), idx_check(i) - 1];
    end
end
idx_remove_sham = unique(idx_remove);

cidx_sham(idx_remove_sham) = [];


idx_retain_odor = find(ismember(cidx_odor+1, cidx_sham));
idx_retain_sham = find(ismember(cidx_sham-1, cidx_odor));

idx_retain_cond_indep = intersect(idx_retain_sham, idx_retain_odor);


% [EEG_Odor, EEG_Odor.lst_changes{end+1,1}] = pop_select( EEG_Odor, ...
%     'trial', idx_retain_odor );
% 
% [EEG_Sham, EEG_Sham.lst_changes{end+1,1}] = pop_select( EEG_Sham, ...
%     'trial', idx_retain_sham );

[EEG_Odor, EEG_Odor.lst_changes{end+1,1}] = pop_select( EEG_Odor, ...
    'trial', idx_retain_cond_indep );

[EEG_Sham, EEG_Sham.lst_changes{end+1,1}] = pop_select( EEG_Sham, ...
    'trial', idx_retain_cond_indep );

end