function playS

% setup
global TDT;
timerT = timer('TimerFcn','runS','Period', 5.0);
TDT = PipeTDT('C:\TDT\Matlab\tnt.rcx');
TDT.runTDT;
ModSc = 0.135; % scaling for 65dB
uModSc = 0.08; % scaling for 65dB
tonSc = 0.1; % base scaling for tone

    function runS
        glonal TDT;
        % set TDT
        TDT.setTDT_PT('UNoiseSc',uModSc);
        TDT.setTDT_PT('MNoiseSc',ModSc);
        TDT.setTDT_PT('ToneSc',tonSc);
        
        % play unmod tone
        TDT.triggerTDT(5);
        start(timerT);
        wait timerT;
        TDT.triggerTDT(6);
        
        % play mod noise
        TDT.triggerTDT(3);
        start(timerT);
        wait timerT;
        TDT.triggerTDT(4);
        
        % end
        TDT.haltTDT;
        clear global TDT;
    end
end
