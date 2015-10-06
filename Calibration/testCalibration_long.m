function [done] = testCalibration_long

% Runs through a set of frequencies and 2 amplitudes and
% records the output from the B&K mic/amplifier setup

global TDT;
global F;
global F_db;
global noiseC;
global A;

% global noiseC_long;
% Frequency
startF = 500; % lowest freq in calibration
Fint = 0.03125; %1/32nd octave 0.03125 % 1/16th octave 0.0625
startF = startF.*(1/power(2,Fint));
nO = 4; % Number of Octaves
Fs = cumprod(ones(1/Fint*nO,1).*power(2,Fint)); % 1/16th octave series
F = Fs.*(ones(1/Fint*nO,1)*startF);
A = (50:5:75);
F_db = nan*ones(numel(F),numel(A));
co = {'r','k','b','g','c','m'};

% ModSc = 0.000110; % scaling for 60dB
% uModSc = 0.000085; % scaling for 60dB

% ModSc = 0.00018; % scaling for 65dB
% uModSc = 0.00014; % scaling for 65dB

% Len = 48000; % length of Analog-to-digital signal to get from TDT
% Fs = 48828.125;

reply = input('Test tone calibration [y/n]?', 's');
% Check tone calibration?
while strcmp(reply,'y')
    % Amplitude
    % dA = str2double(input('Testing Amplitude (dB SPL)', 's'));
    figure;
    for j = 1:numel(A)
        for i=1:size(F,1)
            % compute & set
            TDT.getTDT_V(F(i),A(j));
            TDT.setTDT_PT('ToneFr',TDT.freq);
            TDT.setTDT_PT('ToneSc',TDT.TNR);
            fprintf('Freq is %5i and Ampl is %5.5f V\n', F(i), A(j))
            % turn on tone & start recording
            TDT.triggerTDT(1);
            pause(1)
            % turn off sound & stop recording
            TDT.triggerTDT(2);
            pause(0.2)
            % stop recording
            outA = TDT.RP.ReadTagVEX('In1',0,48000,'F32','F64',1);
            spl = sqrt(mean(outA.^2)); % RMS SPL
            F_db(i,j) = p2db(spl); % dB SPL
            str = strcat('Tone intensity is ',num2str(F_db(i,j)),'dB');
            disp(str);
        end
        semilogx(F,F_db(:,j),'Color',co{j});
        if j==1 % first time
        hold on
        ylim([0 100]);
        xlim([500 8000]);
%         semilogx(400:100:8000,dA,'b-');
        end
    end
    reply = input('Run again [y/n]?', 's');
end

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
end

% When done
done=1;