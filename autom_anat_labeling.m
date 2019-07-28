%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% This atlas needs to have previously been imported %%%
%%%% into the head model file via Brainstorm           %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FilesListHM = dir([folderAtlas,'*head_model.mat']);
% hm = combinedFiles; %load([folderAtlas, FilesListHM(realFilenum).name]);

if strcmpi(EEG.dipfit.coordformat, 'MNI')
    tf = traditionaldipfit([0.0000000000 -26.6046230000 -46.0000000000 0.1234625600 0.0000000000 -1.5707963000 1000.0000000000 1000.0000000000 1000.0000000000]);
elseif strcmpi(EEG.dipfit.coordformat, 'spherical')
    tf = traditionaldipfit([-5.658258      1.039259     -42.80596   -0.00981033    0.03362692   0.004391199      860.8199      926.6112       858.162]);
else
    error('Unknown coordinate format')
end
tfinv = pinv(tf); % the transformation is from HM to MNI (we need to invert it)

for iComp = [1:size(EEG.icaweights,1)] %Default is: iComp = g.components(:)'
    
    atlascoord = tfinv * [EEG.dipfit.model(iComp).posxyz 1]';
        
        % find close location in Atlas
        distance = sqrt(sum((hm.Vertices-repmat(atlascoord(1:3)', [size(hm.Vertices,1) 1])).^2,2));
        [~,selectedPt] = min( distance );
        
        whichVertex = [];
        for vertRow = 1:size(hm.Atlas,2)
           [~, colLocateVertex] = find(hm.Atlas(vertRow).Vertices == selectedPt);
            if istrue(find(hm.Atlas(vertRow).Vertices == selectedPt))
                whichVertex = [whichVertex; vertRow];
            end
        end
        
        if ~isempty(whichVertex)
            EEG.dipfit.model(iComp).areaAAL = hm.Atlas(whichVertex).Label;
        else
            EEG.dipfit.model(iComp).areaAAL = 'no area';
        end
        
end