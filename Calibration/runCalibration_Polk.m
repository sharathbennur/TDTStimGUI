function [done] = runCalibration_Polk

% Runs through a set of frequencies and amplitudes (i.e.TDT voltage) and
% records the voltage input coming from Maria's B&K mic/amplifier setup

global TDT;
TDT.calib = [];

startF = 500; % lowest freq in calibration
Fint = 0.03125; % 0.0078125; % 0.0078125 1/256th octave 
nO = 4; % Number of Octaves
startF = startF.*(1/power(2,Fint));

startA = 0.01; % 0.0000125; % lowest amplitude in calibration 0.0001
nA = 9.5; % # of increases
Aint = 0.0625;
startA = startA.*(1/power(2,Aint));

% setup
Fs = cumprod(ones(1+(1/Fint*nO),1).*power(2,Fint)); % 1/64th octave series
F = Fs.*(ones(1+(1/Fint*nO),1)*startF);
As = cumprod(ones(1+(1/Aint*nA),1).*power(2,Aint)); % 1/16th dB series
A = As.*(ones(1+(1/Aint*nA),1)*startA);
TDT.calib = (ones(numel(F),numel(A),6))*nan;

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
        outA = zeros(2,1);
        outB = zeros(2,1);
        maxA = zeros(2,1);
        for k=1:2
            % turn on tone & start recording
            TDT.triggerTDT(1);
            pause(0.5)
            % turn off sound & stop recording
            TDT.triggerTDT(2);
            pause(0.2)
            % stop recording
            t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
            t_outB = TDT.RP.ReadTagVEX('In3',0,24000,'F32','F64',1);
            maxA(k) = max(t_outA);
            outA(k) = sqrt(mean(t_outA.^2)); % RMS pascal
            outB(k) = sqrt(mean(t_outB.^2)); % RMS V
        end
        % Sound
        TDT.calib(i,j,3) = mean(outA); % RMS pascal
        TDT.calib(i,j,4) = mean(maxA); % max SPL
        TDT.calib(i,j,5) = p2db(TDT.calib(i,j,3)); % dB SPL
        % Stim Voltage
        maxB = max(t_outB);
        TDT.calib(i,j,6) = mean(outB); % RMS V
        disp(strcat(num2str(TDT.calib(i,j,5)),'dB'));
        disp(strcat('RMS=',num2str(TDT.calib(i,j,6)),'V'));
        disp(strcat('Max=',num2str(maxB),'V'));
    end
end

str1 = date;
str = strcat('calib_ParooaTDT_',str1);
calib = TDT.calib;
save(str,'calib');

% save noise SPL
uModSc = 0.0036; % scaling for 65dB 
TDT.setTDT_PT('UNoiseSc',uModSc);
TDT.triggerTDT(5);
pause(2)
% turn off sound & stop recording
TDT.triggerTDT(6);
TDT.noiseC = TDT.RP.ReadTagVEX('In2',0,96000,'F32','F64',1);
noiseC = TDT.noiseC;
str = strcat('noise_ParooaTDT_',str1);
save(str,'noiseC')

% %% TEST - FOR single Freq & Amplitude
% 
% global TDT
% Len = 48000; % length of Analog-to-digital signal to get from TDT
% Fs = 48828.125;
% 
% 
% TDT.setTDT_PT('ToneFr',1000);
% TDT.setTDT_PT('ToneSc',0.1);
% TDT.triggerTDT(1);
% pause(1)
% % turn off sound & stop recording
% TDT.triggerTDT(2);
% pause(0.2)
% % stop recording
% outA = TDT.RP.ReadTagVEX('In1',0,Len,'F32','F64',1);
% % max(outA)
% SPL = sqrt(mean(outA.^2));
% DB = p2db(SPL)
% figure;
% p1 = plot(outA);
% 
% % FFT
% NFFT = 2^nextpow2(Len); % Next power of 2 from length of y
% Y = fft(outA,NFFT)/Len;
% f = Fs/2*linspace(0,1,NFFT/2+1);
% 
% % Plot single-sided amplitude spectrum.
% figure;
% p2 = plot(f,2*abs(Y(1:NFFT/2+1)));
% title('Single-Sided Amplitude Spectrum of y(t)')
% xlabel('Frequency (Hz)')
% ylabel('|Y(f)|')

%% PLOT

% Plot tones
figure;
F =  calib(:,:,1);
A =  calib(:,:,2);
dB = calib(:,:,5);
plot3(F,A,dB)
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