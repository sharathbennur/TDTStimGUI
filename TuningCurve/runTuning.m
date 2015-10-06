function [done] = runTuning

% Plays a range of tone stimuli to generate a full tuning curve

global TDT;

% setup -  TEMP
startF = 500; % lowest freq in calibration
Fint = 0.1; % 1/32nd octave % 0.0078125 1/256th octave
nO = 4; % Number of Octaves
startF = startF.*(1/power(2,Fint));
Fs = cumprod(ones(1+(1/Fint*nO),1).*power(2,Fint)); % 1/32nd octave series
F = Fs.*(ones(1+(1/Fint*nO),1)*startF);
F = flipud(F);
db_list = fliplr(50:5:80);
pause on;

for k=1:5
    for i=1:numel(F)
        for j=1:numel(db_list)
            TDT.getTDT_V(F(i),db_list(j));
            TDT.setTDT_PT('ToneFreq',TDT.freq);
            TDT.setTDT_PT('ToneSc',TDT.TNR);
            TDT.triggerTDT(1);  % turn on tone
            pause(0.1)
            TDT.triggerTDT(2);  % turn off tone
            pause(0.2)
        end
    end
    pause(0.2)
end

done = 1;