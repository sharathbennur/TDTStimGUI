function runTone(btag)

% This function parses the serial port input 'btag' and controls TDT
% stimulus generation. The function has two sections
% Init: setup TDT parameters and task type.
% Run:  Based on task identity (TDT.TT) turn on/off stim in the correct
%       order. The current step (TDT.CS), tracks which step we are on and
%       turns on/off TDT triggers appropriately

% Note: if writing another runXYZ(bTag) script, change the init section to
% setup each trial correctly and change the run section so that the steps for
% each task type match the task structure

global TDT;

% INIT
if numel(btag)>1
    disp('btag is')
    disp(btag);
    % set freq & update # of trials
    TDT.NT = TDT.NT+1;
    TDT.getTDT_V(2000,70);
    TDT.setTDT_PT('ToneFreq',TDT.freq);
    TDT.setTDT_PT('ToneSc',TDT.TNR);
    TDT = TDT.updateCS(1); 
    pause('on')
    TDT.triggerTDT(1);  % turn on tone
    pause(0.4);
    TDT.triggerTDT(2); % turn off tone
    TDT = TDT.updateCS(0); % reset state-list
end

% btag = 'SPKUNT2000END'
% btag = 'SPKMNT2000END'
% btag = 'SPKTON2000END'