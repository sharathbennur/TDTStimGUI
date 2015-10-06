function [done] = testCalibration

% Runs through a set of frequencies and amplitudes (i.e.TDT voltage) and
% records the voltage input coming from Maria's B&K mic/amplifier setup
% USES TEST_CALIB.RCX

global TDT;
global noiseC;

ModSc = 0.0041; % scaling for 60dB
uModSc = 0.003; % scaling for 60dB

Len = 48000; % length of Analog-to-digital signal to get from TDT
Fs = 48828.125;

% Check UnMod Noise?
nr = input('Run UnModNoise? [y/n]', 's');
if strcmp(nr,'y')
    TDT.setTDT_PT('UNoiseSc',uModSc);
    TDT.triggerTDT(5);
    pause(1)
    % turn off sound & stop recording
    TDT.triggerTDT(6);
    noiseC = TDT.RP.ReadTagVEX('In3',0,Len,'F32','F64',1);
    SPL = sqrt(mean(noiseC.^2));
    db = p2db(SPL);
    str = strcat('Noise intensity is ',num2str(db),'dB');
    disp(str);
    
    % plot Noise
    figure;
    % FFT
    NFFT = 2^nextpow2(Len); % Next power of 2 from length of y
    Y = fft(noiseC,NFFT)/Len;
    f = Fs/2*linspace(0,1,NFFT/2+1);
    plot(f,2*abs(Y(1:NFFT/2+1)));
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
    
    % Plot single-sided amplitude spectrum.
    figure;
    Y = p2db(Y);
    plot(f,2*abs(Y(1:NFFT/2+1)));
    xlabel('Frequency (Hz)')
    ylabel('Intensity (dB SPL)')
    xlim([500 16000])
    
    figure;
    spectrogram(noiseC,256,250,256,Fs);
end

% Check ModNoise?
nr = input('Run ModNoise? [y/n]', 's');
if strcmp(nr,'y')
    TDT.setTDT_PT('MNoiseSc',ModSc);
    TDT.triggerTDT(3);
    pause(1)
    % turn off sound & stop recording
    TDT.triggerTDT(4);
    noiseC = TDT.RP.ReadTagVEX('In2',0,Len,'F32','F64',1);
    SPL = sqrt(mean(noiseC.^2));
    db = p2db(SPL);
    str = strcat('Noise intensity is ',num2str(db),'dB');
    disp(str);
    
    % plot Noise
    figure;
    % FFT
    NFFT = 2^nextpow2(Len); % Next power of 2 from length of y
    Y = fft(noiseC,NFFT)/Len;
    f = Fs/2*linspace(0,1,NFFT/2+1);
    plot(f,2*abs(Y(1:NFFT/2+1)));
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
    
    % Plot single-sided amplitude spectrum.
    figure;
    Y = p2db(Y);
    plot(f,2*abs(Y(1:NFFT/2+1)));
    xlabel('Frequency (Hz)')
    ylabel('Intensity (dB SPL)')
    xlim([500 16000])
end

reply = input('Run tone test [y/n]?', 's');
% Check tone calibration?
while strcmp(reply,'y')
    dF = str2double(input('Freq (Hz)?', 's'));
    dA = str2double(input('Testing Amplitude (dB SPL)', 's'));
    % compute & set
    TDT.getTDT_V(dF,dA);
    TDT.setTDT_PT('ToneFr',TDT.freq);
    TDT.setTDT_PT('ToneSc',TDT.TNR);
    fprintf('Freq is %5i and Ampl is %5.5f V\n', dF, dA)
    % turn on tone & start recording
    TDT.triggerTDT(1);
    pause(1)
    % turn off sound & stop recording
    TDT.triggerTDT(2);
    pause(0.2)
    % stop recording
    outA = TDT.RP.ReadTagVEX('In1',0,48000,'F32','F64',1);
    spl = sqrt(mean(outA.^2)); % RMS SPL
    db = p2db(spl); % dB SPL
    str = strcat('Tone intensity is ',num2str(db),'dB');
    disp(str);
    reply = input('Run again [y/n]?', 's');
end

% When done
done=1;