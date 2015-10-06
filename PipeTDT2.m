classdef PipeTDT2 < handle
    
    % Class of matlab objects used to connect to TDT using the RP activeX
    % control and to control stimulus parameters and generation in TDT
    
    % connect to obj RX6 ands set parameters
    properties
        calib = []; % tone calibration data
        mNoise = []; % modulated noise calibration data
        uNoise = []; % unmodulated noise calibration data
        ModSc = []; % voltage for Mod Noise
        uModSc = []; % voltage for unMod Noise
        RP = [];
        freq = 2000;  % default frequency
        RCX = []; % rcx filename and path
        TT = []; % TaskType
        TNR = []; % ToneInNoise ratio
        % functions
        fns = {'Pick A Function','';...
            'runToneNoise','tnt.rcx';...
            'runTuning','tnt.rcx';...
            'runTuning2','tuning.rcx';...
            'runTone','tnt.rcx';...
            'runCalibration3','calib3.rcx';...
            'testCalibration','calib_test.rcx';...
            'testCalibration_long','calib_test.rcx'};
        % Task Types
        TaskT = {}; 
        NT = 0;     % Number of Trials
        CS = 1; % CurrentStep
        evalfn = [];
        noiseC = [];
        dummy = [];
    end
    methods
        % Setup, Connect & Load rcx file
        function obj = PipeTDT2(circ)
            obj.RCX = circ;
            % setup
            obj.RP = actxcontrol('RPco.x',[5 5 26 26]);
            % connect
            if obj.RP.ConnectRX6('GB',1)
                disp('connected')
            else
                error('Unable to connect')
            end
            if exist('calib_current.mat','file')==2
                dt = dir('calib_current.mat');
                obj.dummy = load('calib_current.mat');
                obj.calib = obj.dummy.cTDT.calib;
                obj.mNoise = obj.dummy.cTDT.mNoise;
                obj.uNoise = obj.dummy.cTDT.uNoise;
                st = strcat('Loaded Calibration file dated:',dt.date);
                disp(st);
                % set Noise levels to 60dB
                ModScI = obj.mNoise(:,1)==60;
                obj.ModSc = obj.mNoise(ModScI,2);
                uModScI = obj.uNoise(:,1)==60;
                obj.uModSc = obj.uNoise(uModScI,2);
            end
        end
        function setTDT_PT(obj,tag,val)
            e = obj.RP.SetTagVal(tag,val);
            if e~=1
                error('set parameter failed')
            end
        end
        function writeTDT_TV(obj,tag,val)
            e = obj.RP.WriteTagV(tag,0,val);
            if e~=1
                error('write parameter failed')
            end
        end
        % Trigger Software Trigger
        function triggerTDT(obj,tag)
            e = obj.RP.SoftTrg(tag);
            if e~=1
                error('trigger failed')
            end
        end
        % Setup & Run RCX file
        function runTDT(obj)
            FN = obj.fns{obj.evalfn+(numel(obj.fns)./2)};
            FN = strcat(obj.RCX,FN);
            % Loads circuit file
            obj.RP.ClearCOF();
            e = obj.RP.LoadCOF(FN);
            if e==0
                disp 'Error loading circuit'
            elseif obj.RP.Run();
                d = strcat('Running TDT circuit..',FN);
                disp(d);
            end
            % setup TT (TaskTypes)
            if obj.evalfn==2 % ToneNoise
                obj.TaskT = {'SPKTON',...   % ToneTone trial
                    'SPKUNT',...    % NoiseTone - Unmodulated
                    'SPKMNT',...    % NoiseTone - Modulated
                    'SPKUTI',...    % ToneInNoise - Unmodulated
                    'SPKMTI'};      % ToneInNoise - Modulated
            elseif obj.evalfn==3
                obj.TaskT = 1;
            end
        end
        % Halt & Reset
        function haltTDT(obj)
            if obj.RP.Halt() && obj.RP.ClearCOF();
                disp('Halted RX6 & Reset..');
            else
                disp('Reset failed');
            end         
        end
        % Update current state
        function obj = updateCS(obj,flag)
           if flag==0
               obj.CS = 1; % reset states
           elseif flag==1
               obj.CS = obj.CS+1; % Next state
           end
        end
        % get TDT voltage from calibration data
        function obj = getTDT_V(obj,fs,dbs)
            if ~isempty(obj.calib)
                dB = obj.calib(1,:,2);
                F = obj.calib(:,1,1);
                V = obj.calib(:,:,3);
                V(V>1.22) = NaN; % error check
                % First figure out which Std freq to use
                if fs<500 || fs>16000
                    error('Frequency out of range')
                else
                    [~,Fi] = min(abs(F-fs));
                end
                obj.freq = F(Fi);
                disp(num2str(obj.freq));
                % Figure out V
                dBi = dB==dbs;
                obj.TNR = V(Fi,dBi);
                % error check
                if obj.TNR>1.22
                    error('Voltage over 1.22V')
                end
            end
        end
    end
end