function [freqData ampData permuteMatrix] = tuningCurveTrial(RP)
% init
RCXFile = fullfile('c:\','Stimulus','brodyStimUStimExpt','tuningCurve_for_stg','tuningCurveCode_RZ6_refactor20120705.rcx');
% calibrationFile = []; %include path to calibration file
% calibrationFile = 'C:\Stimulus\calibrationData\20120706\calibration-20120706T151221.mat';
calibrationFile = 'C:\Stimulus\calibrationData\20120801\calibration-20120801T202701.mat';

fs = 24414.125; %hz
% fs = 48828.125; %hz

%params in circuit
%AmpData
%FreqData
%trialDur
%toneDur
% nTicksPerBurst = (toneDur + ibi) * fs* 1000 msec/sec

%load calibration data
calib = load(calibrationFile);
calib=calib.calibrationStructure;
loFreq = 300; %hz
hiFreq = 12000; %hz
freqData = loFreq*10.^(log10(2) * (0:0.33:ceil(log10(hiFreq/loFreq)/log10(2))));

%permuteMatrix = randperm(length(freqData));
 permuteMatrix = [17,16,2,3,11,1,6,14,5,9,15,8,4,13,12,7,10];
%permuteMatrix = [16,2,3,11,1,6,14,5,9,15,8,4,13,12,7,10];
toneDur = 100; %ms
toneSOA = 400; %ms
nTicksPerBurst = ceil((toneDur+toneSOA)/1000* fs);

trialDur = length(permuteMatrix)*(toneDur+toneSOA)+1000; % in ms
% ampData = ones(1,length(freqData)); %place holder; need to generate calibrated 65db voltages for freq set.
ampData = interp1(calib.cf,...
                calib.calibratedamplitude,freqData(permuteMatrix));
%connect to RX6
if ~exist('RP','var') || isempty(RP)
    RP = actxcontrol('RPco.x',[5 5 26 26]);
end
if RP.ConnectRZ6( 'GB', 1)
    fs = RP.GetSFreq;
    disp(['Connected to RX6! fs: ' num2str(fs) 'hz']);
else
    disp('Unable to connect to RX6');
end


RP.ClearCOF();
RP.LoadCOF(RCXFile);

if RP.Run()
    disp('Running circuit!');
else
    disp('Error running circuit!');
end
RP.SetTagVal('toneDur',toneDur);
RP.SetTagVal('nTicksPerBurst',nTicksPerBurst);
RP.SetTagVal('trialDur',trialDur);

RP.WriteTagV('AmpData',0,ampData);
RP.WriteTagV('FreqData',0,freqData(permuteMatrix));

RP.SoftTrg(1);

end