function [EEGout, lst_changes] = f_offlinereference(EEGin, chans, offline_elecref)

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


% Re-referencing function will also erase the channels used for
% rereferencing from dataset, so the next step is commented out since not
% needed
[EEGout, lst_changes] = pop_reref( EEGin, idx_elecref, ...
    'exclude', find(strcmp({EEGin.chanlocs.description}, 'Noisy')));
% 'exclude' tag since data of noisy channels are set to zeros and will be
% interpolated. The exclude tag is defining which channels will be excluded
% from the calculation of the reference values, in the case for example 
% that reference is done with average of all channels, as well as the 
% referencing itself.

% [EEGout, lst_changes{end+1, 1}] = ...
%     f_chan_reject(EEGout, chans, offline_elecref);


end
