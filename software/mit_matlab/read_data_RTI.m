%MIT IAP Radar Course 2011
%Resource: Build a Small Radar System Capable of Sensing Range, Doppler, 
%and Synthetic Aperture Radar Imaging 
%
%Gregory L. Charvat

%Process Range vs. Time Intensity (RTI) plot

%NOTE: set up-ramp sweep from 2-3.2V to stay within ISM band
%change fstart and fstop bellow when in ISM band

clear all;
close all;

%read the raw data .wave file here
[Y,FS,NBITS] = wavread('running_outside_20ms.wav');

%constants
c = 3E8; %(m/s) speed of light

%radar parameters
Tp = 20E-3; %(s) pulse time
N = Tp*FS; %# of samples per pulse
fstart = 2260E6; %(Hz) LFM start frequency for example
fstop = 2590E6; %(Hz) LFM stop frequency for example
%fstart = 2402E6; %(Hz) LFM start frequency for ISM band
%fstop = 2495E6; %(Hz) LFM stop frequency for ISM band
BW = fstop-fstart; %(Hz) transmti bandwidth
f = linspace(fstart, fstop, N/2); %instantaneous transmit frequency

%range resolution
rr = c/(2*BW);
max_range = rr*N/2;

%the input appears to be inverted
trig = -1*Y(:,1);
s = -1*Y(:,2);
clear Y;

%parse the data here by triggering off rising edge of sync pulse
count = 0;
thresh = 0;
start = (trig > thresh);
for ii = 100:(size(start,1)-N)
    if start(ii) == 1 & mean(start(ii-11:ii-1)) == 0
        %start2(ii) = 1;
        count = count + 1;
        sif(count,:) = s(ii:ii+N-1);
        time(count) = ii*1/FS;
    end
end
%check to see if triggering works
% plot(trig,'.b');
% hold on;si
% plot(start2,'.r');
% hold off;
% grid on;

%subtract the average
ave = mean(sif,1);
for ii = 1:size(sif,1);
    sif(ii,:) = sif(ii,:) - ave;
end

zpad = 8*N/2;

%RTI plot
figure(10);
v = dbv(ifft(sif,zpad,2));
S = v(:,1:size(v,2)/2);
m = max(max(v));
imagesc(linspace(0,max_range,zpad),time,S-m,[-80, 0]);
colorbar;
ylabel('time (s)');
xlabel('range (m)');
title('RTI without clutter rejection');

%2 pulse cancelor RTI plot
figure(20);
sif2 = sif(2:size(sif,1),:)-sif(1:size(sif,1)-1,:);
v = ifft(sif2,zpad,2);
S=v;
R = linspace(0,max_range,zpad);
for ii = 1:size(S,1)
    %S(ii,:) = S(ii,:).*R.^(3/2); %Optional: magnitude scale to range
end
S = dbv(S(:,1:size(v,2)/2));
m = max(max(S));
imagesc(R,time,S-m,[-80, 0]);
colorbar;
ylabel('time (s)');
xlabel('range (m)');
title('RTI with 2-pulse cancelor clutter rejection');

% %2 pulse mag only cancelor
% figure(30);
% clear v;
% for ii = 1:size(sif,1)-1
%     v1 = abs(ifft(sif(ii,:),zpad));
%     v2 = abs(ifft(sif(ii+1,:),zpad));
%     v(ii,:) = v2-v1;
% end
% S=v;
% R = linspace(0,max_range,zpad);
% for ii = 1:size(S,1)
%     S(ii,:) = S(ii,:).*R.^(3/2); %Optional: magnitude scale to range
% end
% S = dbv(S(:,1:size(v,2)/2));
% m = max(max(S));
% imagesc(R,time,S-m,[-20, 0]);
% colorbar;
% ylabel('time (s)');
% xlabel('range (m)');
% title('RTI with 2-pulse mag only cancelor clutter rejection');
