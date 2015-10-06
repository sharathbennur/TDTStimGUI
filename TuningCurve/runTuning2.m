function [done] = runTuning2
% Plays a range of tone stimuli to generate a full tuning curve

% SETUP
global TDT;

% setup
startF = 500; % lowest freq in calibration
Fint = 0.1; % 1/32nd octave % 0.0078125 1/256th octave
nO = 4; % Number of Octaves
startF = startF.*(1/power(2,Fint));
Fs = cumprod(ones(1+(1/Fint*nO),1).*power(2,Fint)); % 1/32nd octave series
F = Fs.*(ones(1+(1/Fint*nO),1)*startF);
db_list = 50:5:80;
toneDur = 100;
toneSOA = 200;
fs = 24414.125; %hz

% replicate and randomize indices of db_list and F
db_rept = repmat(db_list',41,1);
F_rept = repmat(F,1,7);
F_rept = F_rept';
F_rept = reshape(F_rept,numel(db_rept),1);
% now randperm
load('stim_seed');
rng(seed)
ord = randperm(size(F_rept,1));
% add 8KHz 85db at the start to figure out timing
F_rep = [8000;F_rept];
fDat = zeros(size(F_rep));
db_rep = [85;db_rept];
vDat = zeros(size(db_rep));

% convert the db_F array into V_F array
cdB = TDT.calib(1,:,2);
cF = TDT.calib(:,1,1);
cV = TDT.calib(:,:,3);
cV(cV>1.22) = NaN; % error check
for i = 1:numel(F_rep)
    [~,Fi] = min(abs(cF-F_rep(i)));
    fDat(i) = cF(Fi);
    % Figure out V
    dBi = cdB==db_rep(i);
    vDat(i) = cV(Fi,dBi);
    % error check
    if vDat(i)>1.22
        error('Voltage over 1.22V')
    end
end
% reorder
t_fDat = fDat(2:end);
fDat(2:end) = t_fDat(ord);
fDat = fDat';
t_vDat = vDat(2:end);
vDat(2:end) = t_vDat(ord);
vDat = vDat';

trialDurn = numel(ord)*(toneDur+toneSOA)+1000; % in ms
nTicksPerBurst = ceil((toneDur+toneSOA)/1000* fs);

pause on;

%% RUN TUNING

TDT.setTDT_PT('ToneDur',toneDur)
TDT.setTDT_PT('TrialDur',trialDurn)
TDT.writeTDT_TV('AmpData',vDat);
TDT.writeTDT_TV('FreqData',fDat);
TDT.setTDT_PT('nTicksPerBurst',nTicksPerBurst);
disp('Running Tuning')

for k=1:2
    disp(num2str(k))
    TDT.triggerTDT(1); % start playing tones
    pause(90)
    TDT.triggerTDT(2); % reset to be able to play again
end

done = 1;