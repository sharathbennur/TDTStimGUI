function [dB] = p2db(p)

% pascal to dB SPL
dB = 20.*(log10((p./0.00002)));
