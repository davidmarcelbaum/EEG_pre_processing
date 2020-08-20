function [EEGout, saveOut] = f_detrend(EEGin, nthOrder, continDetr, whatAboutNaNs)

% nthOrder:      0 or 'constant' for removing mean value
%                1 or 'linear' for linear trend and
%                2 for quadratic trend
% continDetr:    Whether detrend needs to be continuous ('true') or not
%                ('false')
% whatAboutNaNs: 'includenan' � Include NaN values in the input data when
%                computing the trend. Is default!
%                'omitnan' � Ignore all NaN values in the input when
%                computing the trend.


EEGout = nan(size(EEGin, 1), size(EEGin, 2));


for i_chan = 1:size(EEGin, 1)
    
    startChunk  = 1:1:10000;
    midChunk    = ceil(size(EEGin, 2)/2)-5000:1:ceil(size(EEGin, 2)/2)+4999;
    endChunk    = ceil(size(EEGin, 2))-50000:1:ceil(size(EEGin, 2))-40001;
    
    plot([...
        EEGin(i_chan,startChunk), ...
        EEGin(i_chan,midChunk), ...
        EEGin(i_chan,endChunk)])
    
    EEGout(i_chan, :) = detrend(EEGin(i_chan, :), ...
        'Continuous', 0);
    
    hold on
    plot([...
        EEGout(i_chan,startChunk), ...
        EEGout(i_chan,midChunk), ...
        EEGout(i_chan,endChunk)])
    hold off
    
end

saveOut = strcat('Detrending', ...
    '_Order',   num2str(nthOrder), ...
    '_Continuous', num2str(continDetr));

end