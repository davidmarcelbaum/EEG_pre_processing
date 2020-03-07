% I am not sure about the use of the whole EEG.data matrix in same time, so
% it goes through each channel sperately...
for i = 1 : size(EEG.data, 1)
    EEG.data(i, :) = medfilt1(EEG.data(i, :));
end

lst_changes{end+1,1} = 'medfilt1(EEG.data(by_channel, :)';