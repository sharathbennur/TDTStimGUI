function [done] = runCalibration2

% Runs through a set of frequencies and amplitudes (i.e.TDT voltage) and
% records the voltage input coming from Maria's B&K mic/amplifier setup

global TDT;
TDT.calib = [];

startF = 500; % lowest freq in calibration
Fint = 0.03125; % 1/32nd octave % 0.0078125 1/256th octave 
nO = 4; % Number of Octaves
startF = startF.*(1/power(2,Fint));

startA = 0.0001; % 0.0000125; % lowest amplitude in calibration 0.0001
nA = 11; % # of increases
Aint = 0.0625;
startA = startA.*(1/power(2,Aint));

% setup
Fs = cumprod(ones(1+(1/Fint*nO),1).*power(2,Fint)); % 1/64th octave series
F = Fs.*(ones(1+(1/Fint*nO),1)*startF);
As = cumprod(ones(1+(1/Aint*nA),1).*power(2,Aint)); % 1/16th dB series
A = As.*(ones(1+(1/Aint*nA),1)*startA);
TDT.calib = (ones(numel(F),numel(A),5))*nan;

% % Test Script
% F = 2000;
% A = 0.01;

pause on;

% run all combinations
for i=1:numel(F)
        TDT.setTDT_PT('ToneFr',F(i));
    %     for j=1:numel(A)
    for j=1:numel(A)
        % set and save freq & amp
        TDT.setTDT_PT('ToneSc',A(j));
        TDT.calib(i,j,1)=F(i);
        TDT.calib(i,j,2)=A(j);
        fprintf('Freq is %5i and Ampl is %5.5f V\n', F(i), A(j))
        % turn on tone & start recording
        TDT.triggerTDT(1);
        pause(0.5)
        % turn off sound & stop recording
        TDT.triggerTDT(2);
        pause(0.1)
        % stop recording
        t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
%         t_outB = TDT.RP.ReadTagVEX('In3',0,24000,'F32','F64',1);
        maxA = max(t_outA);
        outA = sqrt(mean(t_outA.^2)); % RMS pascal
        % Sound
        TDT.calib(i,j,3) = outA; % RMS pascal
        TDT.calib(i,j,4) = maxA; % max SPL
        TDT.calib(i,j,5) = p2db(TDT.calib(i,j,3)); % dB SPL
        % Stim Voltage
%         maxB = max(t_outB);
        disp(strcat(num2str(TDT.calib(i,j,5)),'dB'));
%         disp(strcat('Max=',num2str(maxB),'V'));
    end
end

str1 = date;
str = strcat('calib_ParooaTDT_',str1);
calib = TDT.calib;
save(str,'calib');

% save noise SPL
uModSc = 0.0036; % scaling for 60dB 
TDT.setTDT_PT('UNoiseSc',uModSc);
TDT.triggerTDT(5);
pause(1)
% turn off sound & stop recording
TDT.triggerTDT(6);
TDT.noiseC = TDT.RP.ReadTagVEX('In2',0,96000,'F32','F64',1);
noiseC = TDT.noiseC;
str = strcat('noise_ParooaTDT_',str1);
save(str,'noiseC')

%% Create FIR filter for noise flattening
SPL = TDT.calib(:,:,5);
SPL_m = mean(SPL,1);
[~,I] = min(abs(SPL_m-60));
gain_list = SPL(:,I)-60;
freq_list = TDT.calib(:,1,1);

% format freq list & gain list for fir2
nyquist = 24414.0625;
freq_list = freq_list./nyquist;
freq_list = vertcat(0,freq_list,1);
gain_list = vertcat(0,gain_list,0);

ntaps = 250;
filtcoefs = fir2(ntaps,freq_list,10.^(gain_list/20));
fileid = fopen('C:\TDT\MyFIRcoefs.txt','wt+');
count = fprintf(fileid,'%4.6f\n',filtcoefs);
str = strcat(num2str(count),' bytes written');
disp(str);
fclose(fileid);

%% PLOT

% Plot tones
F =  calib(:,:,1);
A =  calib(:,:,2);
dB = calib(:,:,5);
figure;
surf(F,A,dB)

% Plot Noise
Len = 96000; % length of Analog-to-digital signal to get from TDT
Fs = 48828.125;
figure;

NFFT = 2^nextpow2(Len); % Next power of 2 from length of y
Y = fft(noiseC,NFFT)/Len;
f = Fs/2*linspace(0,1,NFFT/2+1);
Y = p2db(Y);
plot(f,2*abs(Y(1:NFFT/2+1)));

Y = fft(noiseC,64)/Len;
f = Fs/2*linspace(0,1,64/2+1);
Y = p2db(Y);
% plot(f,2*abs(Y(1:512/2+1)));
% hold on
plot(f,2*abs(Y(1:64/2+1)),'*');
% xlim([100 10000]);

figure;
spectrogram(noiseC,256,250,256,Fs);

done = 1;