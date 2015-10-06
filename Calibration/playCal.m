% test script for db-V search function

global TDT;
newV = '0.001';
V = 0.001;
newdB = '65';

TDT.setTDT_PT('ToneFr',2000)
% while ~strcmp(newV,'0')
%     newV = input('New Voltage to use?', 's');
%     TDT.setTDT_PT('ToneSc',str2double(newV));
%     TDT.triggerTDT(1);
%     pause(0.5)
%     % turn off sound & stop recording
%     TDT.triggerTDT(2);
%     pause(0.2)
%     % stop recording
%     t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
%     outA = sqrt(mean(t_outA.^2)); % RMS pascal
%     curr_db = p2db(outA);
%     disp(strcat(num2str(newV),'V'));
%     disp(strcat(num2str(curr_db),'dB'));
% end

TDT.setTDT_PT('ToneSc',V);
TDT.triggerTDT(1);
pause(0.5)
% turn off sound & stop recording
TDT.triggerTDT(2);
pause(0.2)
% stop recording
t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
outA = sqrt(mean(t_outA.^2)); % RMS pascal
curr_db = p2db(outA);
disp(strcat(num2str(V),'V'));
disp(strcat(num2str(curr_db),'dB'));

while ~strcmp(newdB,'0')
    newdB = input('New db to calibrate?', 's');
    dB = str2double(newdB);
    diff = dB - curr_db;
    while abs(diff)>=0.1
        if diff>1
            V = V*(1+(diff/5)*0.79);
        elseif diff>0 && diff<=1
            V = V*(1+(diff/5)*0.2);
        elseif diff<-1
            V = V/(1+abs(diff/5)*0.78);
        elseif diff<0 && diff >=-1
            V = V*(1+(diff/5)*0.2);
        end
        TDT.setTDT_PT('ToneSc',V);
        TDT.triggerTDT(1);
        pause(0.5)
        % turn off sound & stop recording
        TDT.triggerTDT(2);
        pause(0.2)
        % stop recording
        t_outA = TDT.RP.ReadTagVEX('In1',0,24000,'F32','F64',1);
        outA = sqrt(mean(t_outA.^2)); % RMS pascal
        curr_db = p2db(outA);
        disp(strcat(num2str(V),'V'));
        disp(strcat(num2str(curr_db),'dB'));
        diff = dB - curr_db;
    end
    disp('calibrated')
end