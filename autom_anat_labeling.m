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
    
    atlascoord = tfinv * [EEG.dipfit.model(iComp).posxyz 1]'; %This seems rights, since in Brainstorm coordinates XYZ are in MNI format.
    %dipoles coordinates (posxyz) are now atlascoordinates MNIxyz (based on fiducials)
    
        % find close location in Atlas
        distance = sqrt(sum((hm.Vertices-repmat(atlascoord(1:3)', [size(hm.Vertices,1) 1])).^2,2));
        [~,selectedPt] = min( distance );
        
        %AAL atlas
        rowContainsVertexAAL = [];
        for vertRow = 1:size(hm.AtlasAAL,2)
           [~, colLocateVertex] = find(hm.AtlasAAL(vertRow).Vertices == selectedPt);
            if istrue(find(hm.AtlasAAL(vertRow).Vertices == selectedPt))
                rowContainsVertexAAL = [rowContainsVertexAAL; vertRow];
            end
        end
        
        if ~isempty(rowContainsVertexAAL)
            
            areaCatenation = [];
            for Stringnum = 1:size(rowContainsVertexAAL,1) %For some vertices, the atlas contains more than one area
                %Usually, these areas are adjacent, but still would like to
                %check!
                %This code makes sure we do not loose any area information.
                
                areaCatenation = [areaCatenation, hm.AtlasAAL(rowContainsVertexAAL(Stringnum)).Label, ', '];
            end
                %EEG.dipfit.model(iComp).areaAAL = hm.Atlas(rowContainsVertex).Label;
                EEG.dipfit.model(iComp).areaAAL = areaCatenation;
        else
            EEG.dipfit.model(iComp).areaAAL = 'no area';
        end
        
        %SVREG atlas
        rowContainsVertexSVREG = [];
        for vertRow = 1:size(hm.AtlasSVREG,2)
           [~, colLocateVertex] = find(hm.AtlasSVREG(vertRow).Vertices == selectedPt);
            if istrue(find(hm.AtlasSVREG(vertRow).Vertices == selectedPt))
                rowContainsVertexSVREG = [rowContainsVertexSVREG; vertRow];
            end
        end
        
        if ~isempty(rowContainsVertexSVREG)
            
            areaCatenation = [];
            for Stringnum = 1:size(rowContainsVertexSVREG,1) %For some vertices, the atlas contains more than one area
                %Usually, these areas are adjacent, but still would like to
                %check!
                %This code makes sure we do not loose any area information.
                
                areaCatenation = [areaCatenation, hm.AtlasSVREG(rowContainsVertexSVREG(Stringnum)).Label, ', '];
            end
                %EEG.dipfit.model(iComp).areaAAL = hm.Atlas(rowContainsVertex).Label;
                EEG.dipfit.model(iComp).areaSVREG = areaCatenation;
        else
            EEG.dipfit.model(iComp).areaSVREG = 'no area';
        end
        
end