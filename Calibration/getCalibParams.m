function [fo,ao] = getCalibParams(fi,ai)

% inputs: frequency(fi) & amplitude in dbSPL(ai)
% outputs: frequency(fo) & TDT voltage (ao)

if exist('calib_current.mat','file')==2
    calib = load('calib_current.mat');
    F = calib(:,1,1);
    A = calib(1,:,2)';
    % First figure out which Std freq to use
    [dummy,Fi] = min(abs(F-fi));
    fo = F(Fi);
    % Now interpolate and find TDT voltage
    dB = calib(Fi,:,5)'; % dBs list for Freq(fo)
    ao = interp1(dB,A,ai,'spline');
else
    error('No Calibration File!')
end
