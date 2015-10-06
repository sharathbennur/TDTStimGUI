% load last calibration file and make a new FIR filter

 % make sure noise generating .rcx file in TDT has this sampling rate
nyquist = 24414.0625;
load('calib_current');

SPL = calib(:,:,5);
SPL_m = mean(SPL,1);
[C,I] = min(abs(SPL_m-65));
gain_list = SPL(:,I)-65;
freq_list = calib(:,1,1);

ntaps = 250;

filtcoefs = fir2(ntaps,freq_list,10.^(gain_list/20));
fileid = fopen('C:\TDT\MyFIRcoefs.txt','wt+');
count = fprintf(fileid,'%4.6f\n',filtcoefs);
str = strcat(num2str(count),' bytes written');
disp(str);
fclose(fileid);

%% testing

subplot(2,1,1);
filtresp = fft(filtcoefs,1000);
plot(freq_list*nyquist,gain_list, 'b-o',linspace(0,nyquist,...
    length(filtresp)/2),20*log10(abs(filtresp(1:length(filtresp)/2))),'r');
xlabel('Frequency (Hz)'); ylabel('Gain (dB)');
xlim([500 16000]);

subplot(2,1,2);
plot(filtcoefs);
xlabel('Coefficient number'); ylabel('Coefficient value');

%% OLD VERSION FROM TDT NEWSLETTER

% save FIR coefs from TDT's SigCalRP to a text file that can be used by the
% FIR filter in RPvdsEx

% Ref: http://www.tdt.com/news/Newsletters/Summer2005.htm

load('gain_list.mat');
load('freq_list.mat');

ntaps = 250;
nyquist = 24414.0625;
filtcoefs = fir2(ntaps,freq_list,10.^(gain_list/20));
fileid = fopen('C:\TDT\MyFIRcoefs.txt','wt+');
count = fprintf(fileid,'%4.6f\n',filtcoefs);
str = strcat(num2str(count),' bytes written');
disp(str);
fclose(fileid);
