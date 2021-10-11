function normalizedData = f_normalize_EEG(rawData, dim_timeSeries)

% dim_timeSeires    = dimension of the time series along rows or columns

if dim_timeSeries == 1
    rawData = permute(rawData, [2 1]);
end


for i_TS = size(rawData, 1)
    
    std_TS = std(rawData(i_TS, :);
    
    % Scale time points between -1 and 1 around 0 based on -std and std as
    % being min and max, respectively
    normalizedData(i_TS, size(rawData(i_TS,:), 2)) = ...
        zeros(size(rawData, 1), size(rawData(i_TS,:), 2));
    for i_pnt = 1 : size(rawData(i_TS,:), 2)
        normalizedData(i_TS, i_pnt) = ...
            2 * ( (rawData(i_TS, i_pnt) - std_TS) ) / (std_TS + std_TS) +1;
    end
    
    % A sample figure for comparing ori vs notmalized data
    figure
    plot(normalizedData(i_TS:30000))
    title(strcat('normalized', {' '}, num2str(std_TS)))
    figure
    plot(rawData(i_TS:30000))
    title('original')
    
end

end