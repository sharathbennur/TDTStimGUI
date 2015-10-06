function runToneNoise2(btag)

% This function parses the serial port input 'btag' and controls TDT
% stimulus generation. The function has two sections
% Init: setup TDT parameters and task type.
% Run:  Based on task identity (TDT.TT) turn on/off stim in the correct
%       order. The current step (TDT.CS), tracks which step we are on and 
%       turns on/off TDT triggers appropriately

% Note: if writing another runXYZ(bTag) script, change the init section to
% setup each trial correctly and change the run section so that the steps for 
% each task type match the task structure
% USES TNT.RCX

global TDT;

ModSc = 0.0041; % scaling for 60dB
uModSc = 0.003; % scaling for 60dB

% INIT
if numel(btag)>1
    % parse btag looking for task type & freq
    TDT.TT = find(strncmp(btag,TDT.TaskT,6));
    if TDT.TT==4
        % set TNR into TDT
        TNR = str2double(btag(strfind(btag,'&')+1:strfind(btag,'END')-1));
        freq = str2double(btag(7:strfind(btag,'&')-1));
        TDT.getTDT_V(freq,TNR);
        TDT.setTDT_PT('ToneFreq',TDT.freq);
        TDT.setTDT_PT('ToneSc',TDT.TNR);
        TDT.setTDT_PT('UNoiseSc',uModSc);
        TDT.setTDT_PT('MNoiseSc',ModSc);
    elseif TDT.TT==5
        % set TNR into TDT
        TNR = str2double(btag(strfind(btag,'&')+1:strfind(btag,'END')-1));
        freq = str2double(btag(7:strfind(btag,'&')-1));
        TDT.getTDT_V(freq,TNR);
        TDT.setTDT_PT('ToneSc',TDT.TNR);
        TDT.setTDT_PT('UNoiseSc',uModSc);
        TDT.setTDT_PT('MNoiseSc',ModSc);
    else
        freq = str2double(btag(7:strfind(btag,'END')-1));
        TDT.getTDT_V(freq,70); 
        TDT.setTDT_PT('ToneSc',TDT.TNR); 
        TDT.setTDT_PT('UNoiseSc',uModSc);
        TDT.setTDT_PT('MNoiseSc',ModSc);
    end
    % set freq & update # of trials
    TDT.NT = TDT.NT+1;
    TDT.setTDT_PT('ToneFreq',TDT.freq);
    % reset state-list
    TDT = TDT.updateCS(0);
% RUN
else
%     TDT.TT
%     TDT.CS
    switch TDT.TT
        case 1 % Tone trial
            switch btag
                case  '5' % ToneOn
                    TDT.triggerTDT(1);  % turn on tone
                case '9'        
                    TDT.triggerTDT(2); % turn off tone
                    TDT = TDT.updateCS(0); % reset state-list
            end
        case 2 % UnModNoiseTone trial
            switch btag
                case '5'
                    switch TDT.CS
                        case 1 % turn on Unoise
                            TDT.triggerTDT(5);
                            TDT = TDT.updateCS(1);
                        case 3 % turn on tone
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                    end 
                case '9'
                    switch TDT.CS
                        case 1||3||5
                            TDT = TDT.updateCS(0); % reset
                        case 2
                            TDT.triggerTDT(6); % turn off Unoise
                            TDT = TDT.updateCS(1); 
                        case 4
                            TDT.triggerTDT(2); % Tone off
                            TDT = TDT.updateCS(1); 
                    end
            end
        case 3 % ModNoiseTone trial
            switch btag
                case '5'
                    switch TDT.CS
                        case 1 % turn on Mnoise
                            TDT.triggerTDT(3);
                            TDT = TDT.updateCS(1);
                        case 3 % turn on tone
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                    end 
                case '9'
                    switch TDT.CS
                        case 1||3||5
                            TDT = TDT.updateCS(0); % reset
                        case 2
                            TDT.triggerTDT(4); % turn off Mnoise
                            TDT = TDT.updateCS(1); 
                        case 4
                            TDT.triggerTDT(2); % Tone off
                            TDT = TDT.updateCS(1); 
                    end
            end
        case 4 % ToneInUnmodNoise trial
            switch btag
                case '5'
                    switch TDT.CS
                        case 1 % turn on Unoise & Tone
                            TDT.triggerTDT(5); % Noise on first
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                        case 3 % turn on tone
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                    end 
                case '9'
                    switch TDT.CS
                        case 1||3||5
                            TDT = TDT.updateCS(0); % reset
                        case 2
                            TDT.triggerTDT(2); % Tone off first
                            TDT.triggerTDT(6); 
                            TDT = TDT.updateCS(1); 
                        case 4
                            TDT.triggerTDT(2); % Tone off
                            TDT = TDT.updateCS(1); 
                    end
            end
        case 5 % ToneInUnmodNoise trial
            switch btag
                case '5'
                    switch TDT.CS
                        case 1 % turn on Unoise & Tone
                            TDT.triggerTDT(3); % Noise on first
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                        case 3 % turn on tone
                            TDT.triggerTDT(1);
                            TDT = TDT.updateCS(1);
                    end 
                case '9'
                    switch TDT.CS
                        case 1||3||5
                            TDT = TDT.updateCS(0); % reset
                        case 2
                            TDT.triggerTDT(2); % Tone off first
                            TDT.triggerTDT(4); 
                            TDT = TDT.updateCS(1); 
                        case 4
                            TDT.triggerTDT(2); % Tone off
                            TDT = TDT.updateCS(1); 
                    end
            end
    end
end

% btag = 'SPKUNT2000END'
% btag = 'SPKMNT2000END'
% btag = 'SPKTON2000END'