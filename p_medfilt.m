% |===USER INPUT===|
lst_changes{end+1,1} = 'EEG = medfilt1(EEG.data(by_channel, :)';
% |=END USER INPUT=|


% Running medfilt on all channels at once will generate a vector;
% Therefore, run it per channel
for i = 1 : size(EEG.data, 1)
    EEG.data(i, :) = medfilt1(EEG.data(i, :));
end
