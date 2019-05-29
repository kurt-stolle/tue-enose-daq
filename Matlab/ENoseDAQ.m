% ENoseDAQ implements a data aquisition device for an electronic nose that is controlled via an Arduino Nano
%
% K.H.W. Stolle <k.h.w.stolle@gmail.com>
% 2019-03-15N
%
%

classdef ENoseDAQ < handle
    properties (SetAccess = private)
        s; % Serial connection handle
        started logical; % started
        isValid logical; % whether this is a valid instance
    end
    methods
        function enose = ENoseDAQ(comPort, continuous, callback)
            % check whether there is already an ENoseDAQ connected
            delete(instrfind({'Port', 'Tag'}, {comPort, 'ENoseDAQ'}));
            
            % open a new serial connection
            enose.s = serial(comPort,'BaudRate',115200, 'Tag', 'ENoseDAQ');
            %enose.s.InputBufferSize = 10 * 17 * 200;
            
            % streaming mode
            if continuous
                enose.s.BytesAvailableFcnCount = 4*17+1;
                enose.s.BytesAvailableFcnMode = 'byte';
                enose.s.BytesAvailableFcn = @(~,~) callback();
            end
            
            % open stream
            fopen(enose.s);
            
            % the program running on the arduino should have reset now,
            % wait until we receive the 'ready' signal
            msg = fscanf(enose.s,'%s\n');
            assert(numel(msg)<=5,"ready signal not received fully");
            msg = msg(end-4:end);
            assert(strcmp(msg,'ready'),"expected ready but received '" + msg +"' instead.");
            
            enose.isValid = true;
        end
        
        function v = IsValid(enose)
            v = enose.isValid;
        end
        
        function delete(enose)
            % stop gracefully by closing the serial connection
            fclose(enose.s);
            delete(enose.s);
        end
        
        % reset stops measurements
        function reset(enose)
            enose.sendCommand("r");
            enose.started = false;
            msg = fscanf(enose.s,'%s\n');
            disp(msg);
            enose.clear();
        end
        
        % start will start a stream of measurements
        function start(enose)
            enose.sendCommand('m');
            enose.started = true;
        end
        
        % isStarted
        function s = isStarted(enose)
            s = enose.started;
        end
        
        % read reads a measurement from Serial
        function m = read(enose)
            t = fread(enose.s,1,'float32');
            d = fread(enose.s,8,'int16');
            
            m = [t,d'];
        end
        
        % program delays
        function delayMark(enose, time)
            enose.sendCommand("d" + int2str(time));
        end
        
        % program valve
        function switchValve(enose, state)
            enose.sendCommand("f" + int2str(state));
        end
        
        
        % capture captures for a certain amount of milliseconds and then
        % stops capturing
        function c = capture(enose,time, marks)
            % Calculate how many measurements to expect
            fs = enose.getSampleRate();
            samples = fs*time;
            
            % Allocate c
            c = zeros(samples,9);
            
            % Take the calculated amount of measurements
            enose.switchValve(0);
            enose.start();
            if exist('marks','var')
                for i=1:numel(marks)
                    enose.delayMark(marks(i))
                    enose.switchValve(mod(i,2))
                end
            end
            enose.delayMark(time)
            for n=1:samples
                c(n,:) = enose.read();
            end
            enose.reset();
        end
        
        % dataAvailable returns true if there is data available
        function d = dataAvailable(enose)
            d = (enose.s.bytesAvailable ~= 0);
        end
        
        % measurementsAvailable returns the amount of measurments that may
        % be read from the input
        function m = measurementsAvailable(enose)
            if enose.started == false
                m = 0;
                return;
            end
            m = floor(enose.s.bytesAvailable/17);
        end
        
        % clear wipes all data
        function clear(enose)
            %             while enose.dataAvailable()
            %                 fread(enose.s,1,'int8');
            %             end
            if enose.s.BytesAvailable > 0
                fread(enose.s, enose.s.BytesAvailable);
            end
        end
        
        % setSampleRate sets the sample rate in Hz
        function setSampleRate(enose,rate)
            enose.sendCommand("s" + int2str(rate));
        end
        
        % getSamplingRate returns fs
        function fs = getSampleRate(enose)
            enose.sendCommand('i');
            fs = fscanf(enose.s,'%d\n');
        end
        
        % setSensitivity sets the calibration values [0,255]
        function setSensitivity(enose,sensor,value)
            enose.sendCommand("c" + int2str(sensor) + ":" + int2str(value));
        end
        
        % sendCommand issues a raw command
        function sendCommand(enose,cmd)
            % send a command over Serial
            fprintf(enose.s,cmd);
            
            if enose.started
                return
            end
            
            % read 'ok' or something else
            msg = fscanf(enose.s,'%s\n');
            assert(strcmp(msg,'ok'),"command '"+cmd+"' failed: " + msg);
        end
    end
end