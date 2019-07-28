%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Guidelines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ### This script follows the following pre-processing pipeline:        ###
% . _RAW: conversion to .set format                                     ###
% .. _Filt(0,1-45): Filtering highpass o.1Hz and lowpass 45Hz           ###
% ... _Re-reference: referenced to user-chosen reference                ###
% .... _ChInterpol: Interpolating noisy channels                        ###
% ..... _ICAWeights: ICA has been performed on dataset                  ###
% ...... _ICAClean: Artefactial IC removed                              ###
% ....... _EpochsICAWeights: Cutting dataset into epochs                ###
% ........ _SelectedEpochs: Noisy epochs have been rejected             ###

% ### This script will proecss ALL datasets of the same type of a given ###
% ### folder. Many options will automatically be determined by the first###
% ### dataset the script encounters. Be sure to isolate your datasets!  ###


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Some prerequisities in order for the script to function %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%This will avoid asking again each time the script is restarted unless the
%user chooses to.
if exist('pathName', 'var') && exist('conservedCharacters', 'var') && exist('scriptPart', 'var') && exist('preProcessingFolder', 'var') && exist('stepLevel', 'var')
    startPointScript = questdlg('Do you want to (re)initialize variables?', ...
        'Start from scratch?', ...
        'Yes','No','No');
    
    switch startPointScript
        case 'Yes'
            prerequisities
        case ''
            prerequisities
    end
    
else
    prerequisities
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Integrating last inputs and starting script %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

startTime = datetime(now,'ConvertFrom','datenum');

switch scriptPart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
        
        %Call for code file
        rawfiltref
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 2 %In case "Interpolation of noisy channels" selected
        
        %Call for code file
        interpolation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 3 %In case "ICA" selected
        
        %Call for code file
        ica
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 4 %In case "Epoching" selected
        
        %Call for code file
        epoching
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 5 %In case "Extract channel interpolation information" selected
        
        %Call for code file
        extractinterpolation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 6 %In case "Compute dipoles ..." selected
        
        %Call for code file
        dipoles
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 7 %In case "Organize Triggers" selected
        
        %Call for code file
        organizetriggers
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 8 %In case "Reject empty channels" selected
        
        %Call for code file
        rejempty
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 9 %In case 'Transform chanlocs.xyz to .elc' selected
        
        %Call for code file
        xyz2elc
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
    case 10 %In case 'Asign altas areas to dipoles' selected
        
        %Call for code file
        computeatlas2areas
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    otherwise %If nothing has been selected or "Cancel" button clicked
        warning('No option for pre-processing has been chosen');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% End of script execution %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Filenum == numel(FilesList) && Filenum ~= 0
    
    switch scriptPart
        case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script RAWed ' string(cyclesRunRAW) ' of ' string(numel(FilesList)) ' datasets',...
                'Script filtered ' string(cyclesRunFilt) ' of ' string(numel(FilesList)) ' datasets',...
                'Script re-referenced ' string(cyclesRunReref) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderRAW,...
                folderFilt,...
                folderReference});
        case 2 %In case "Interpolation of noisy channels" selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderChInterpol});
        case 3 %In case "ICA" selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderICAWeights});
        case 4 %In case "Epoching" selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderEpochs});
        case 5 %In case "Extract channel interpolation information" selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderInterpolInfo});
        case 6 %In case "Compute dipoles ..." selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script computed dipoles for ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderDipoles});
        case 7 %In case "Organize Triggers" selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderOrganizeTriggers});
        case 8 %In case empty channels rejection selected
            endMsg = msgbox({'Operation Completed', duration: datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script processed ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderRejEmptyChan});
        case 10 %In case atlas computation selected
            endMsg = msgbox({'Operation Completed', datetime(now,'ConvertFrom','datenum') - startTime,...
                ' ',...
                'Script asigned atlas areas for ' string(cyclesRun) ' of ' string(numel(FilesList)) ' datasets',...
                ' ',...
                'Datasets have been saved in',...
                folderAtlas});    
    end
    
elseif Filenum == 0
    msgbox({'The folder you pointed to does not seem to contain any datasets.'});
end
