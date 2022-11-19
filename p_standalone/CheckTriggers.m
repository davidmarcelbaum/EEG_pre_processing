pathNew = ['D:\germanStudyData\datasetsSETS\Ori_PlaceboNight\', ...
    'preProcessing\TRIALS_Oct'];

pathOld = ['D:\germanStudyData\datasetsSETS\Ori_PlaceboNight\', ...
    'preProcessing\EEGLABFilt_Mastoids_Off_On_200Hz_Oct'];

filesNew = dir(pathNew);
filesOld = dir(pathOld);

% Clean file lists
filesNew(~contains({filesNew.name}, 'OFF_ON')) = [];
filesOld(~contains({filesOld.name}, 'OFF_ON')) = [];

isdifferent = zeros(1, length(filesNew));

for i = 1:length(filesNew)
    
    if ~strcmp(filesOld(i).name, filesNew(i).name)
        error('You tried to compare the uncomparable')
    end
   
    fileNew = load([pathNew, filesep, filesNew(i).name]);
    fileOld = load([pathOld, filesep, filesOld(i).name]);
    
    % New
    triggersNew     = {fileNew.events.mffkey_cidx};
    triggersNew     = cellfun(@str2double,triggersNew);
    
    triggersNew(isnan(triggersNew)) =[];
    idx_triggersNew = find(ismember(cellfun(@str2double, ...
        {fileNew.events.mffkey_cidx}), triggersNew));
    
    % Old
    triggersOld     = {fileOld.events.mffkey_cidx};
    triggersOld     = cellfun(@str2double,triggersOld);
    
    triggersOld(isnan(triggersOld)) =[];
    idx_triggersOld = find(ismember(cellfun(@str2double, ...
        {fileOld.events.mffkey_cidx}), triggersOld));
    
    if numel(triggersOld) ~= numel(triggersNew)
        isdifferent(i) = 1;
    else
        for i_trigger = 1:numel(idx_triggersOld)
            
            if triggersOld(i_trigger) ~= triggersNew(i_trigger)
                isdifferent(i) = 1;
            end
            if idx_triggersOld(i_trigger) ~= idx_triggersOld(i_trigger)
                isdifferent(i) = 1;
            end
            if ~strcmp(fileOld.events(i_trigger).code, ...
                    fileNew.events(i_trigger).code) && ...
                    ~isempty(fileOld.events(i_trigger).code)
                isdifferent(i) = 1;
            end
            if fileOld.events(idx_triggersOld(i_trigger)).offset ~= ...
                    fileNew.events(idx_triggersOld(i_trigger)).offset && ...
                    fileOld.events(idx_triggersOld(i_trigger)).offset ~= 0
                isdifferent(i) = 1;
            end
            if fileOld.events(idx_triggersOld(i_trigger)-1).offset ~= ...
                    fileNew.events(idx_triggersOld(i_trigger)-1).offset && ...
                    fileOld.events(idx_triggersOld(i_trigger)-1).offset ~= -3000
                isdifferent(i) = 1;
            end
            
        end
    end
    
end

sum(isdifferent) / numel(isdifferent) * 100