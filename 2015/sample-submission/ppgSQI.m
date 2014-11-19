function [psqi]=ppgSQI(ppg,ann_ppg)
% PPG Signal Quality Index based on beat template correlation.
% 
% input: 
%     ppg:      PPG data; 
%     annppg:   PPG annotation time (samples)
% output:
%     psqi:     PPG SQI
%
% Written by Qiao Li, November 10, 2014.
% Last Modified: November 10, 2014
 
Fs=125;
% Create PPG template
[t v]=template(ppg,ann_ppg);

for j=1:length(ann_ppg)-1
% Calculate correlation coefficients based on the template length
    beatbegin=ann_ppg(j);
    beatend=ann_ppg(j+1);
    if beatend-beatbegin>3*Fs
        beatend=beatbegin+3*Fs;
    end
    templatelength=length(t);
    if beatbegin+templatelength-1 > length(ppg) || beatend > length(ppg) || beatbegin < 1
        continue;
    end
    currentb=j;
    cc=corrcoef(t,ppg(beatbegin:beatbegin+templatelength-1));
    c1(j)=cc(1,2);
    if (c1(j)<0)
        c1(j)=0;
    end
    psqi(currentb)=c1(j);
end
end

function [t valid] = template(wave,anntime,temp_ahead,samp_freq)
% PPG waveform template creation.
% Written by Qiao Li, February 21, 2011.
% 
% input: 
%     wave:       PPG data; 
%     anntime:    PPG annotation time (sample)%     
%     temp_ahead: N samples before the beginning of PPG waveform mark,
%                 default is 0
%     samp_freq:  sampling frequency, default is 125Hz
% output:
%     t:          PPG waveform template based on normal-length beats
%     valid:      1 for valid template
%                 0 for invalid template

if nargin < 4
    samp_freq = 125;
end

if nargin < 3
    temp_ahead = 0;
end

t=[];
valid=0;

% according to heart rate max(300bpm) and min(20bpm) to get max and min
% beat-by-beat interval
hr_max=300;
bb_interval_min=samp_freq*60/hr_max;
hr_min=20;
bb_interval_max=samp_freq*60/hr_min;

% Normal beat thresholds
normal_beat_length_min=0.7;
normal_beat_lentth_max=1.5;
normal_beat_percent_threshold=0.5;

% using xcorr to get the basic period of the PPG as the length of template
y=xcorr(detrend(wave));

len=length(wave);
lena=length(anntime);
i=len+1;

[pks,locs] = findpeaks(y(i:end));
if isempty(pks) 
    return;
end
[c i]=max(pks);
i=locs(i);

cycle=samp_freq;
if i<len-1
    cycle=i;
end

% cumulate the beats with reasonable length to get template

if lena<2
    return;
end
    
p0=1;
i=anntime(p0);
while i-temp_ahead <1 
    p0=p0+1;
    if (p0>lena)
        t=wave;
        valid=0;
        return;
    end
    i=anntime(p0);
end

if p0+1>=lena
    return;
end

beat_interval=diff(anntime(p0:length(anntime)));
median_bi=median(beat_interval);
if ~isnan(median_bi)
    temp_peak=abs(locs-median_bi);
    [m i]=min(temp_peak);
    cycle=locs(i);
else
    return;
end
   
% the length of template valid detection
valid=1;
if cycle > bb_interval_max || cycle < bb_interval_min
    valid=0;
    t=zeros(1,cycle);
    return;
end
    
n=0;
d1=0;
invalidn=0;
currentbeatlength=anntime(p0+1)-anntime(p0);
if currentbeatlength>0
    d1=wave(i-temp_ahead:i+cycle-1);
    n=1;
else
    invalidn=invalidn+1;
    d1=zeros(cycle+temp_ahead,1);
end
    
p0=p0+1;
if p0<lena-1
    i=anntime(p0);
    n=1;
    invalidn=0;
    while i<len-cycle && p0<lena-1
        currentbeatlength=anntime(p0+1)-anntime(p0);
        if currentbeatlength>0
            d1=d1+wave(i-temp_ahead:i+cycle-1);
            n=n+1;
        else
            invalidn=invalidn+1;
        end
        p0=p0+1;
        i=anntime(p0);
    end
    d1=d1./n;
    % normal beat is less than the reasonable percentage of all beats
    if (n/(n+invalidn))<normal_beat_percent_threshold
        valid=0;
    end
else
    valid=0;
end
t=d1;
end
