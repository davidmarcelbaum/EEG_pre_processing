%% Guidelines
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

%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --------------------------- User input ---------------------------------

% Reject unwanted channels
chans2rej       = {'M1';'M2';'HEO';'VEO';'EKG';'EMG'};  % cell array of 
                                                        % channel labels

chansempty      = {}; % Cell array of labels of empty channels

data_subgrp     = 'SleepStimulation';   % string of data types { ...
                                        % 'RestingState', ...
                                        % 'Learn', ...
                                        % 'Learn_Houses', ...
                                        % 'Learn_Faces', ...
                                        % 'PreSleep', ...
                                        % 'Houses_PreSleep', ...
                                        % 'Faces_PreSleep', ...
                                        % 'SleepStimulation', ...
                                        % 'PostSleep', ...
                                        % 'Houses_PostSleep', ...
                                        % 'Faces_PostSleep', ...
                                        % 'OdorDifferentiation', ...
                                        % }
                                        
s_session       = {};   % If multiple sessions, specify by name which one
                        % you are interested in. Leave empty for all.
                        % {'Night_1', 'Night_2', 'Night_3'}

% ------------------------- End of user input -----------------------------
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Some prerequisities in order for the script to function

%This will avoid asking again each time the script is restarted unless the
%user chooses to.
if exist('pathName', 'var') && exist('scriptPart', 'var') && ...
        exist('preProcessingFolder', 'var') && exist('stepLevel', 'var')
    
    init_vars = 'No'; % String 'Yes' or 'No' to reinitialize variables
    
    if strcmp(init_vars, 'Yes')
            prerequisities
    end
    
else
    prerequisities
end

%% Integrating last inputs and starting script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

startTime = datetime(now, 'ConvertFrom', 'datenum');

switch scriptPart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    case 1 %In case "RAWing, Filtering and/or re-referencing" selected %%%%
        
        %Call for code file
        rawfiltref
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 2 %In case "Interpolation of noisy channels" selected
        
        %Call for code file
        interpolation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 3 %In case "ICA" selected
        
        %Call for code file
        ica
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 4 %In case "Epoching" selected
        
        %Call for code file
        epoching
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 5 %In case "Extract channel interpolation information" selected
        
        %Call for code file
        extractinterpolation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 6 %In case "Compute dipoles ..." selected
        
        %Call for code file
        dipoles
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 7 %In case "Organize Triggers" selected
        
        %Call for code file
        organizetriggers
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 8 %In case "Reject empty channels" selected
        
        %Call for code file
        rejempty
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 9 %In case 'Transform chanlocs.xyz to .elc' selected
        
        %Call for code file
        xyz2elc
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
    case 10 %In case 'Asign altas areas to dipoles' selected
        
        %Call for code file
        computeatlas2areas
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    otherwise %If nothing has been selected or "Cancel" button clicked
        warning('No option for pre-processing has been chosen');
end

%% End script feedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Filenum == numel(FilesList) && Filenum ~= 0
    
    endMsg = msgbox({'Operation Completed', ...
        datetime(now,'ConvertFrom','datenum') - startTime, ' ', ...
        'Script processed ' string(cyclesRun) ' of ' ...
        string(numel(FilesList)) ' datasets', ' ', ...
        'Datasets have been saved in', string(foldersCreated)});

end
