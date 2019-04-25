% ENose Capturing tool
%
% MATLAB 2017.a
%
% K.H.W. Stolle <k.h.w.stolle@gmail.com> 
% 2019-03-15
clear;

% Configuration variables
com_port = 'COM4';
data_label = "unknown";

% Open the ENoseDAQ
enose = ENoseDAQ(com_port,0,0);
enose.setSampleRate(300); 
enose.setSensitivity(1,128);
enose.setSensitivity(2,128);
enose.setSensitivity(3,128);
enose.setSensitivity(4,128);
enose.setSensitivity(5,128);
enose.setSensitivity(6,128);
enose.setSensitivity(7,128);
enose.setSensitivity(8,128);

data = enose.capture(8); % s

delete(enose);

% Save the data to a file
csvwrite(data_label + "_" + datestr(now,'yyyy-mm-dd_HH-MM-SS') + ".csv",data);

% Plot the data
t = data(:,1);
sensors = 5 * data(:,2:9) / 1024;

figure; 
plot(t,sensors);
xlabel("Time t [s]");
ylabel("Sensor reading s_i [V]");
axis([min(t) max(t) min(sensors(:))*0.9 max(sensors(:))*1.1]);
legend("MQ-2","MQ-3","MQ-4","MQ-5","MQ-6","MQ-7","MQ-8","MQ-138");
