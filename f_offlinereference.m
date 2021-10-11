function [EEGout, lst_changes] = f_offlinereference(EEGin, chans, ...
    offline_elecref)

if ischar(offline_elecref) || iscell(offline_elecref)
    idx_elecref = find(strcmp({EEGin.chanlocs.type}, offline_elecref));
elseif isnumeric(offline_elecref) || isempty(offline_elecref)
    idx_elecref = offline_elecref;
end

%% Extract position of noisy channel and find closest channel to it
log_noisy = find(strcmp({EEGin.chanlocs(idx_elecref).description}, 'Noisy'));

for i_elec = log_noisy
    noise.idx               = idx_elecref(i_elec);
    noise.x                 = EEGin.chanlocs(noise.idx).X;
    noise.y                 = EEGin.chanlocs(noise.idx).Y;
    noise.z                 = EEGin.chanlocs(noise.idx).Z;
    
    distances               = nan(EEGin.nbchan, 3);
    abs_dist                = nan(EEGin.nbchan, 1);
    for i_chan = 1:EEGin.nbchan
        if i_chan == noise.idx
            continue
        end
        distances(i_chan, :) = [...
            EEGin.chanlocs(i_chan).X - EEGin.chanlocs(noise.idx).X, ...
            EEGin.chanlocs(i_chan).Y - EEGin.chanlocs(noise.idx).Y, ...
            EEGin.chanlocs(i_chan).Z - EEGin.chanlocs(noise.idx).Z];
        abs_dist(i_chan) = sum(abs(distances(i_chan, :)));
    end
    neighb_idx              = find(abs_dist == min(abs_dist));
    idx_elecref(i_elec)     = neighb_idx;
    
end

% End check up whether chosen references are 'Noisy'
if any(strcmp({EEGin.chanlocs(idx_elecref).description}, 'Noisy'))
    error('New references are also noisy')
end

% Determine which is the channel that is exceptionally used for
% re-referencing but which needs to be recreated for further analysis
idx_rebuild = idx_elecref(...
    ~strcmp({EEGin.chanlocs(idx_elecref).type}, offline_elecref));
str_rebuild = {EEGin.chanlocs(idx_rebuild).labels};


% Re-referencing function will also erase the channels used for
% rereferencing from dataset, so the next step is commented out since not
% needed
if ~isempty(str_rebuild)
    
    % This is a particular situation: Offline referencing is done with a
    % channel that was not declared as reference, but will be used
    % regardless since the reference channel is noisy and this is the
    % channel next to it.
    % We need to retain this channel and to give information that this
    % channel has been used for referencing.
    [EEGout, lst_changes] = pop_reref( EEGin, idx_elecref, ...
        'exclude', find(strcmp({EEGin.chanlocs.description}, 'Noisy')), ...
        'keepref', 'on');
    
    [EEGout] = f_chan_reject(EEGout, chans, offline_elecref);
    
    for i_reb = 1:numel(str_rebuild)
        chan_loc = ...
            find(strcmp({EEGout.chanlocs.labels}, str_rebuild(i_reb)));
        EEGout.data(chan_loc, :) = zeros;
        EEGout.chanlocs(chan_loc).description = 'OffReference';
    end
else
    [EEGout, lst_changes] = pop_reref( EEGin, idx_elecref, ...
        'exclude', find(strcmp({EEGin.chanlocs.description}, 'Noisy')));
end
% 'exclude' tag since data of noisy channels are set to zeros and will be
% interpolated. The exclude tag is defining which channels will be excluded
% from the calculation of the reference values, in the case for example 
% that reference is done with average of all channels, as well as the 
% referencing itself.


end
