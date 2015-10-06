function [done] = runCalibration3

% QUEST version of calibration
% Calibrates list of frequencies (F) for intensities (db_list)
% USES CALIB3.RCX

global TDT;
TDT.calib = [];

% setup
startF = 500; % lowest freq in calibration
Fint = 0.03125; % 1/32nd octave % 0.0078125 1/256th octave
nO = 4; % Number of Octaves
startF = startF.*(1/power(2,Fint));
Fs = cumprod(ones(1+(1/Fint*nO),1).*power(2,Fint)); % 1/32nd octave series
F = Fs.*(ones(1+(1/Fint*nO),1)*startF);
db_list = 50:5:85;
n_list = 50:5:70;
VUL = 1.22; % Voltage Upper Limit
ld = 0.1; % low delta for incrementing voltage
hd = 0.78; % high delta for incrementing voltage

% other params
initV = 0.0001; % 0.0000125; % lowest amplitude in calibration 0.0001
tO = 0.5; % StimulusOn time
acc = 0.1; % accuracy of calibration in dB SPL

TDT.calib = (ones(numel(F),numel(db_list),3))*nan;
TDT.mNoise = (ones(numel(n_list),2))*nan;
TDT.uNoise = (ones(numel(n_list),2))*nan;
pause on;

%% Calibrate Tones

% run all combinations
for i=1:numel(F)
    TDT.setTDT_PT('ToneFr',F(i));
    for j=1:numel(db_list) % dBs to calibrate
        if j==1 % First time for this F
            % Print and save params
            fprintf('Now Calibrating %5i Hz at %5.1f dB SPL\n', F(i),db_list(j));
            TDT.calib(i,j,1) = F(i);
            TDT.calib(i,j,2) = db_list(j);
            % get initial values
            TDT.setTDT_PT('ToneSc',initV);
            TDT.triggerTDT(1);
            pause(tO)
            % turn off sound & stop recording
            TDT.triggerTDT(2);
            pause(0.2)
            % stop recording
            t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
            outA = sqrt(mean(t_outA.^2)); % RMS pascal
            curr_db = p2db(outA);
            disp(strcat(num2str(initV),'V'));
            disp(strcat(num2str(curr_db),'dB'));
            diff = db_list(j) - curr_db;
            V = initV;
            while abs(diff)>=acc
                if diff>1
                    V = V*(1+(diff/5)*hd);
                elseif diff>0 && diff<=1
                    V = V*(1+(diff/5)*ld);
                elseif diff<-1
                    V = V/(1+abs(diff/5)*hd);
                elseif diff<0 && diff >=-1
                    V = V/(1+(diff/5)*ld);
                end
                if V>VUL
                    disp('**********Voltage set is >1.22V************')
                    diff = 0; % leave that as a NaN
                else
                    TDT.setTDT_PT('ToneSc',V);
                    TDT.triggerTDT(1);
                    pause(tO)
                    % turn off sound & stop recording
                    TDT.triggerTDT(2);
                    pause(0.2)
                    % stop recording
                    t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
                    outA = sqrt(mean(t_outA.^2)); % RMS pascal
                    curr_db = p2db(outA);
                    disp(strcat(num2str(V),'V'));
                    disp(strcat(num2str(curr_db),'dB'));
                    diff = db_list(j) - curr_db;
                end
            end
            TDT.calib(i,j,3) = V; % save the voltage
            disp('----------calibrated----------')
        else
            % Print and save params
            fprintf('Now Calibrating %5i Hz at %5.1f dB SPL\n', F(i),db_list(j));
            TDT.calib(i,j,1) = F(i);
            TDT.calib(i,j,2) = db_list(j);
            diff = db_list(j) - curr_db;
            while abs(diff)>=acc
                if diff>1
                    V = V*(1+(diff/5)*hd);
                elseif diff>0 && diff<=1
                    V = V*(1+(diff/5)*ld);
                elseif diff<-1
                    V = V/(1+abs(diff/5)*hd);
                elseif diff<0 && diff >=-1
                    V = V/(1+(diff/5)*ld);
                end
                if V>VUL
                    disp('**********Voltage set is >1.22V************')
                    diff = 0; % leave that as a NaN
                else
                    TDT.setTDT_PT('ToneSc',V);
                    TDT.triggerTDT(1);
                    pause(tO)
                    % turn off sound & stop recording
                    TDT.triggerTDT(2);
                    pause(0.2)
                    % stop recording
                    t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
                    outA = sqrt(mean(t_outA.^2)); % RMS pascal
                    curr_db = p2db(outA);
                    disp(strcat(num2str(V),'V'));
                    disp(strcat(num2str(curr_db),'dB'));
                    diff = db_list(j) - curr_db;
                end
            end
            if V<=VUL
                TDT.calib(i,j,3) = V; % save the voltage
            end
            disp('----------calibrated----------')
        end
    end
end

%% find Voltages for mod noise

for j=1:numel(n_list) % dBs to calibrate
    if j==1 % First time for this F
        % Print and save params
        fprintf('Now Calibrating modNoise at %5.1f dB SPL\n',n_list(j));
        TDT.mNoise(j,1) = n_list(j);
        TDT.setTDT_PT('MNoiseSc',initV);
        TDT.triggerTDT(3);
        pause(1)
        % turn off sound & stop recording
        TDT.triggerTDT(4)
        pause(0.2);
        noiseC = TDT.RP.ReadTagVEX('In2',0,48000,'F32','F64',1);
        SPL = sqrt(mean(noiseC.^2));
        curr_db = p2db(SPL);        
        disp(strcat(num2str(initV),'V'));
        str = strcat('Noise:',num2str(curr_db),'dB');
        disp(str);
        diff = n_list(j) - curr_db;
        V = initV;
        while abs(diff)>=acc
            if diff>1
                V = V*(1+(diff/5)*hd);
            elseif diff>0 && diff<=1
                V = V*(1+(diff/5)*ld);
            elseif diff<-1
                V = V/(1+abs(diff/5)*hd);
            elseif diff<0 && diff >=-1
                V = V/(1+(diff/5)*ld);
            end
            TDT.setTDT_PT('MNoiseSc',V);
            TDT.triggerTDT(3);
            pause(1)
            % turn off sound & stop recording
            TDT.triggerTDT(4);
            pause(0.2);
            % stop recording
            noiseC = TDT.RP.ReadTagVEX('In2',0,48000,'F32','F64',1);
            SPL = sqrt(mean(noiseC.^2));
            curr_db = p2db(SPL);
            disp(strcat(num2str(V),'V'));
            str = strcat('Noise:',num2str(curr_db),'dB');
            disp(str);
            diff = n_list(j) - curr_db;
        end
        TDT.mNoise(j,2) = V; % save the voltage
        disp('----------calibrated----------')
    else
        % Print and save params
        fprintf('Now Calibrating modNoise at %5.1f dB SPL\n',n_list(j));
        TDT.mNoise(j,1) = n_list(j);
        diff = n_list(j) - curr_db;
        while abs(diff)>=acc
            if diff>1
                V = V*(1+(diff/5)*hd);
            elseif diff>0 && diff<=1
                V = V*(1+(diff/5)*ld);
            elseif diff<-1
                V = V/(1+abs(diff/5)*hd);
            elseif diff<0 && diff >=-1
                V = V/(1+(diff/5)*ld);
            end
            if V>VUL
                disp('**********Voltage set is >1.22V************')
                diff = 0; % leave that as a NaN
            else
                TDT.setTDT_PT('MNoiseSc',V);
                TDT.triggerTDT(3);
                pause(1)
                % turn off sound & stop recording
                TDT.triggerTDT(4);
                pause(0.2);
                % stop recording
                noiseC = TDT.RP.ReadTagVEX('In2',0,48000,'F32','F64',1);
                SPL = sqrt(mean(noiseC.^2));
                curr_db = p2db(SPL);
                disp(strcat(num2str(V),'V'));
                str = strcat('Noise:',num2str(curr_db),'dB');
                disp(str);
                diff = n_list(j) - curr_db;
            end
        end
        if V<=VUL
            TDT.mNoise(j,2) = V; % save the voltage
        end
        disp('----------calibrated----------')
    end
end

%% find Voltages for Unmod noise

for j=1:numel(n_list) % dBs to calibrate
    if j==1 % First time for this F
        % Print and save params
        fprintf('Now Calibrating unmodNoise at %5.1f dB SPL\n',n_list(j));
        TDT.uNoise(j,1) = n_list(j);
        TDT.setTDT_PT('UNoiseSc',initV);
        TDT.triggerTDT(5);
        pause(1)
        % turn off sound & stop recording
        TDT.triggerTDT(6)
        pause(0.2);
        noiseC = TDT.RP.ReadTagVEX('In3',0,48000,'F32','F64',1);
        SPL = sqrt(mean(noiseC.^2));
        curr_db = p2db(SPL);        
        disp(strcat(num2str(initV),'V'));
        str = strcat('Noise:',num2str(curr_db),'dB');
        disp(str);
        diff = n_list(j) - curr_db;
        V = initV;
        while abs(diff)>=acc
            if diff>1
                V = V*(1+(diff/5)*hd);
            elseif diff>0 && diff<=1
                V = V*(1+(diff/5)*ld);
            elseif diff<-1
                V = V/(1+abs(diff/5)*hd);
            elseif diff<0 && diff >=-1
                V = V/(1+(diff/5)*ld);
            end
            TDT.setTDT_PT('UNoiseSc',V);
            TDT.triggerTDT(5);
            pause(1)
            % turn off sound & stop recording
            TDT.triggerTDT(6);
            pause(0.2);
            % stop recording
            noiseC = TDT.RP.ReadTagVEX('In3',0,48000,'F32','F64',1);
            SPL = sqrt(mean(noiseC.^2));
            curr_db = p2db(SPL);
            disp(strcat(num2str(V),'V'));
            str = strcat('Noise:',num2str(curr_db),'dB');
            disp(str);
            diff = n_list(j) - curr_db;
        end
        TDT.uNoise(j,2) = V; % save the voltage
        disp('----------calibrated----------')
    else
        % Print and save params
        fprintf('Now Calibrating unmodNoise at %5.1f dB SPL\n',n_list(j));
        TDT.uNoise(j,1) = n_list(j);
        diff = n_list(j) - curr_db;
        while abs(diff)>=acc
            if diff>1
                V = V*(1+(diff/5)*hd);
            elseif diff>0 && diff<=1
                V = V*(1+(diff/5)*ld);
            elseif diff<-1
                V = V/(1+abs(diff/5)*hd);
            elseif diff<0 && diff >=-1
                V = V/(1+(diff/5)*ld);
            end
            if V>VUL
                disp('**********Voltage set is >1.22V************')
                diff = 0; % leave that as a NaN
            else
                TDT.setTDT_PT('UNoiseSc',V);
                TDT.triggerTDT(5);
                pause(1)
                % turn off sound & stop recording
                TDT.triggerTDT(6);
                pause(0.2);
                % stop recording
                noiseC = TDT.RP.ReadTagVEX('In3',0,48000,'F32','F64',1);
                SPL = sqrt(mean(noiseC.^2));
                curr_db = p2db(SPL);
                disp(strcat(num2str(V),'V'));
                str = strcat('Noise:',num2str(curr_db),'dB');
                disp(str);
                diff = n_list(j) - curr_db;
            end
        end
        if V<=VUL
            TDT.uNoise(j,2) = V; % save the voltage
        end
        disp('----------calibrated----------')    
    end
end

str1 = date;
str = strcat('calib_ParooaTDT_',str1);
cTDT.calib = TDT.calib;
cTDT.uNoise = TDT.uNoise;
cTDT.mNoise = TDT.mNoise;
save(str,'cTDT');

%% Create FIR filter for noise flattening
SPL = TDT.calib(1,:,2);
SPL_m = mean(SPL,1);
[~,I] = min(abs(SPL_m-60));
gain_list = SPL(:,I)-60;
freq_list = TDT.calib(:,1,1);

% % format freq list & gain list for fir2
% nyquist = 24414.0625;
% freq_list = freq_list./nyquist;
% freq_list = vertcat(0,freq_list,1);
% gain_list = vertcat(0,gain_list,0);
% 
% ntaps = 250;
% filtcoefs = fir2(ntaps,freq_list,10.^(gain_list/20));
% fileid = fopen('C:\TDT\MyFIRcoefs.txt','wt+');
% count = fprintf(fileid,'%4.6f\n',filtcoefs);
% str = strcat(num2str(count),' bytes written');
% disp(str);
% fclose(fileid);

%% Done flag
done = 1;

%% Plot calibration

calib = TDT.calib;
db = calib(1,:,2);
freq = calib(:,1,1);
V = calib(:,:,3);
V(V>1.22) = NaN;
figure('color',[1,1,1]);
semilogy(freq,V,'LineWidth',2)
hold on
xlabel('Frequency (Hz)')
ylabel('Voltage(V)')
legend('50','55','60','65','70','75','80','85')
ylim([0,1.22])