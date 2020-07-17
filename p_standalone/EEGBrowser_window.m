h2 = EEGBrowser(EEG);

set(gcf,'units','normalized','outerposition',[0 0 1 1])

% Make the buttons a bit smaller
h2.figureHandle.Children(1).Position = [0.8126 0.0981 0.0421 0.036];
h2.figureHandle.Children(2).Position = [0.7705 0.0981 0.0421 0.036];
h2.figureHandle.Children(3).Position = [0.7284 0.0981 0.0421 0.036];
h2.figureHandle.Children(4).Position = [0.4600 0.0981 0.0421 0.036];
h2.figureHandle.Children(5).Position = [0.5705 0.0981 0.0421 0.036];
h2.figureHandle.Children(6).Position = [0.6137 0.0981 0.0421 0.036];
h2.figureHandle.Children(7).Position = [0 0 0 0];
% h2.figureHandle.Children(8).Position = [0.7705 0.0981 0.0421 0.036];
% h2.figureHandle.Children(9).Position = [0.1 0.0981 0.1 0.036];
% h2.figureHandle.Children(10).Position = [0.1 0.0981 0.0421 0.036];
% h2.figureHandle.Children(11).Position = [0.1 0.0981 0.0421 0.036];
h2.figureHandle.Children(12).Position = [0.2958 0.0981 0.0421 0.036];
h2.figureHandle.Children(13).Position = [0.2526 0.0981 0.0421 0.036];
h2.figureHandle.Children(14).Position = [0.2095 0.0981 0.0421 0.036];
h2.figureHandle.Children(15).Position = [0.1663 0.0981 0.0421 0.036];

% By default, the window has a lot of empty space --> Take advantage
h2.axesHandle.Position = [0.025,0.155,0.96,0.84];