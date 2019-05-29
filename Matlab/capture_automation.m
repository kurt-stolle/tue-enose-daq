% ENose Capturing tool
%
% MATLAB 2017.a
%
% K.H.W. Stolle <k.h.w.stolle@gmail.com>
% 2019-03-15

% Configuration variables -- configure capture.m first!
nMeasurements = 25;
interMeasurementDelay = 10;
comPort = 'COM8';
data_label='hoegaarden-wit';

% Automatic script run with delays
for i=1:nMeasurements
    disp("preparing for measurement " + num2str(i));
    pause(interMeasurementDelay);
    capture(comPort,data_label);
end