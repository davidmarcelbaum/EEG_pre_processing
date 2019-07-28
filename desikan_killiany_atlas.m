%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% This is extracted and adapted from the            %%%
%%%% eeg_compatlas.m of the dipfit plugin              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function EEG = eeg_compatlas(EEG, varargin)

%if nargin < 1
%    help eeg_compatlas;
%    return
%end

if ~isfield(EEG, 'dipfit') || isempty(EEG.dipfit) || ~isfield(EEG.dipfit, 'model') || isempty(EEG.dipfit.model)
    error('You must run dipole localization first');
end

% decode options
% --------------
%g = finputcheck(varargin, ...
%    { 'atlas'      'string'    {'dk' }     'dk';
%    'components' 'integer'   []          [1:size(EEG.icaweights,1)] });
%if isstr(g), error(g); end;

% loading hm file
FilesListHM = dir([folderAtlas,'*head_model.mat']);
hm = load([folderHM, FilesListHM(realFilenum).name]);

if isdeployed
    stdHM = load('-mat', fullfile( eeglabFolder, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
    if ~exist(meshfile)
        error(sprintf('headplot(): deployed mesh file "%s" not found\n','head_modelColin27_5003_Standard-10-5-Cap339.mat'));
    end
else
    p  = fileparts(which('eeglab.m'));
    stdHM = load('-mat', fullfile( p, 'functions', 'supportfiles', 'head_modelColin27_5003_Standard-10-5-Cap339.mat'));
end


% coord transform to the HM file space
if strcmpi(EEG.dipfit.coordformat, 'MNI')
    tf = traditionaldipfit([0.0000000000 -26.6046230000 -46.0000000000 0.1234625600 0.0000000000 -1.5707963000 1000.0000000000 1000.0000000000 1000.0000000000]);
elseif strcmpi(EEG.dipfit.coordformat, 'spherical')
    tf = traditionaldipfit([-5.658258      1.039259     -42.80596   -0.00981033    0.03362692   0.004391199      860.8199      926.6112       858.162]);
else
    error('Unknown coordinate format')
end
tfinv = pinv(tf); % the transformation is from HM to MNI (we need to invert it)

% scan dipoles
fprintf('Looking up brain area in the Desikan-Killiany Atlas\n');
for iComp = [1:size(EEG.icaweights,1)] %Default is: iComp = g.components(:)'
    if size(EEG.dipfit.model(iComp).posxyz,1) == 1
        atlascoord = tfinv * [EEG.dipfit.model(iComp).posxyz 1]';
        
        % find close location in Atlas
        distance = sqrt(sum((hm.Vertices-repmat(atlascoord(1:3)', [size(hm.Vertices,1) 1])).^2,2));
        % distance = sqrt(sum((hm.VertNormals-repmat(atlascoord(1:3)', [size(hm.VertNormals,1) 1])).^2,2));
        
        
        % compute distance to each brain area
        [~,selectedPt] = min( distance );
        area = stdHM.atlas.colorTable(selectedPt);
        if area > 0
            EEG.dipfit.model(iComp).areadk = stdHM.atlas.label{area};
        else
            EEG.dipfit.model(iComp).areadk = 'no area';
        end
        
        fprintf('Component %d: area %s\n', iComp, EEG.dipfit.model(iComp).areadk);
    else
        if ~isempty(EEG.dipfit.model(iComp).posxyz)
            fprintf('Component %d: cannot find brain area for bilateral dipoles\n', iComp);
        else
            fprintf('Component %d: no location (RV too high)\n', iComp);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%