function alarmResult=challenge(recordName,alarm_type)
%
%  alarmResult=challenge(recordName,alarm_type)
%
% Sample entry for the 2015 PhysioNet/CinC Challenge.
%
% Inputs:
%   recordName
%       String specifying the record name to process
%   alarmType
%       String specifying the alarm type. Alarm types are:
%             Asystole, Bradycardia, Tachycardia,
%             Ventricular_Tachycardia, Ventricular_Flutter
%
%
% Outputs:
%   alarmResult
%       Integer value where 0 = false alarm and 1 is a true
%       alarm. 
%
%
% To run your entry on the entire training set in a format that is
% compatible with PhysioNet's scoring enviroment, run the script
% generateValidationSet.m
%
% Dependencies:
%
%       1) This function does not requires that you have the WFDB
%       App Toolbox installed. 
%       A matlab function 'rdmat' can read the data instead of using WFDB
%       Toolbox.
%
%       2) The CHALLENGE function requires that you have downloaded the challenge
%       data 'set-p' in a subdirectory of the current directory. The subdirectory
%       should be called '/challenge/2015/set-p/' . The 'set-p' dataset can
%       be downloaded from PhysioNet at:
%           http://physionet.org/physiobank/database/challenge/2015/
%          
%         This dataset is used by the generateValidationSet.m script to
%         create the annotations on your traing set that will be used to 
%         verify that your entry works properly in the PhysioNet testing 
%         environment. 
%
% Version 0.5
%
%
% Written by Qiao Li, November 10, 2014.
% Last Modified: Ikaro Silva February 11, 2015
%
%
%
% %Example using training data- 
% alarmResult=challenge('./challenge/set-p/100','Asystole')
%

% Name of file containing answers
answers = 'answers.txt';

%Get all ECG, blood pressure and photoplethysmogram signals
[~,signal,Fs,siginfo]=rdmat(recordName);
alarmResult=1;
description=squeeze(struct2cell(siginfo));
description=description(4,:);

% Resample signal to 125Hz
Fs=Fs(1);
if Fs~=125
    signal=resample(signal,125,Fs);
    Fs=125;
end

%%Users can access the raw samples of the record by running the following
%command if WFDB Toolbox installed:
%[tm,signal]=rdsamp(recordName);
%
%%For more information please see the help in RDSAMP

%Run WABP on the record, which by default will analyze the first ABP, ART, or BP signal
N=[];
N0=[];
abp_ind=get_index(description,'ABP');
ann_abp=[];
features=[];
BEATQ=[];
R=[];
if(~isempty(abp_ind))
   ann_abp=wabp(signal(:,abp_ind),0,1);
   % Analyze the signal quality index of ABP using jSQI
   if length(ann_abp)>=3 % at least 3 abp beats detected
        [features] = abpfeature(signal(:,abp_ind),ann_abp);
        [BEATQ R] = jSQI(features, ann_abp, signal(:,abp_ind));
   end
end

%Run WABP on the record of 'PLETH' to analyze photoplethysmogram signal
ppg_ind=get_index(description,'PLETH');
ann_ppg=[];
if (~isempty(ppg_ind))
    y=quantile(signal(:,ppg_ind),[0.05,0.5,0.95]);
    ann_ppg=wabp(signal(:,ppg_ind),0,(y(3)-y(1))/120);
    % Analyze the signal quality index of PPG 
    if ~isempty(ann_ppg)
        [psqi]=ppgSQI(signal(:,ppg_ind),ann_ppg);
    end
end



%Make decisions

% set valid data segment for decision making, 16s before the alarm
N_d=Fs*5*60; % alarm position
N0_d=N_d-Fs*16+1; % 16s before the alarm

% select the beats in the segment
n_abp_beats=intersect(find(ann_abp>=N0_d),find(ann_abp<=N_d));
n_ppg_beats=intersect(find(ann_ppg>=N0_d),find(ann_ppg<=N_d));

hr_max_abp=NaN;
max_rr_abp=NaN;
hr_max_ppg=NaN;
max_rr_ppg=NaN;

% calculate the heart rate
if length(n_abp_beats)>=2
    hr_max_abp=60*Fs/min(diff(ann_abp(n_abp_beats)));
    max_rr_abp=max(diff(ann_abp(n_abp_beats)))/Fs;
end
if length(n_ppg_beats)>=2
    hr_max_ppg=60*Fs/min(diff(ann_ppg(n_ppg_beats)));
    max_rr_ppg=max(diff(ann_ppg(n_ppg_beats)))/Fs;
end
    
% calculate low heart rate of 5 consecutive beats for Bradycardia
low_hr_abp=NaN;
low_hr_ppg=NaN;
if length(n_abp_beats>=5)
    for i=1:length(n_abp_beats)-4
        low_hr_abp(i)=60*Fs/((ann_abp(n_abp_beats(i+4))-ann_abp(n_abp_beats(i)))/4);
    end
end
low_hr_abp=min(low_hr_abp);
if length(n_ppg_beats>=5)
    for i=1:length(n_ppg_beats)-4
        low_hr_ppg(i)=60*Fs/((ann_ppg(n_ppg_beats(i+4))-ann_ppg(n_ppg_beats(i)))/4);
    end
end
low_hr_ppg=min(low_hr_ppg);
        
% calculate high heart reate of 17 consecutive beats for Tachycardia
high_hr_abp=NaN;
high_hr_ppg=NaN;
if length(n_abp_beats>=17)
    for i=1:length(n_abp_beats)-16
        high_hr_abp(i)=60*Fs/((ann_abp(n_abp_beats(i+16))-ann_abp(n_abp_beats(i)))/16);
    end
end
high_hr_abp=max(high_hr_abp);
if length(n_ppg_beats>=17)
    for i=1:length(n_ppg_beats)-16
        high_hr_ppg(i)=60*Fs/((ann_ppg(n_ppg_beats(i+16))-ann_ppg(n_ppg_beats(i)))/16);
    end
end
high_hr_ppg=max(high_hr_ppg);

% calculate the signal quality index
if ~isempty(ann_abp)
    abpsqi=1-sum(sum(BEATQ(intersect(n_abp_beats,1:length(BEATQ)),:)))/numel(BEATQ(intersect(n_abp_beats,1:length(BEATQ)),:));
else
    abpsqi=0;
end
if ~isempty(ann_ppg)
    ppgsqi=mean(psqi(intersect(n_ppg_beats,1:length(psqi))));
else
    ppgsqi=0;
end

% SQI threshold
sqi_th = 0.9;

% Alarm threshold (seconds)
ASY_th = 4;
BRA_th = 40;
TAC_th = 140;
VTA_th = 100;
VFB_th = 250;
tolerance = 5; % tolerance = 5 bmp
switch alarm_type
    case 'Asystole'
        % if the signal quality is good enough and the maximum RR interval
        % is less than the Asystole threshold, set the alarm as 'F'
        if (abpsqi>=sqi_th && max_rr_abp<ASY_th) || (ppgsqi>=sqi_th && max_rr_ppg<ASY_th)
            alarmResult=0;
        end
    case 'Bradycardia'
        % if the signal quality is good enough and the low heart rate
        % is greater than the Bradycardia threshold, set the alarm as 'F'
        if (abpsqi>=sqi_th && low_hr_abp-tolerance>BRA_th) || (ppgsqi>=sqi_th && low_hr_ppg-tolerance>BRA_th)
            alarmResult=0;
        end
    case 'Tachycardia'
        % if the signal quality is good enough and the high heart rate
        % is less than the Tachycardia threshold, set the alarm as 'F'
        if (abpsqi>=sqi_th && high_hr_abp+tolerance<TAC_th) || (ppgsqi>=sqi_th && high_hr_ppg+tolerance<TAC_th)
            alarmResult=0;
        end
    case 'Ventricular_Tachycardia'
        % suppress false alarm using hr_max & sqi
        if (abpsqi>=sqi_th && hr_max_abp+tolerance<VTA_th) || (ppgsqi>=sqi_th && hr_max_ppg+tolerance<VTA_th)
            alarmResult=0;
        end
    case 'Ventricular_Flutter'
        % suppress false alarm using hr_max & sqi
        if (abpsqi>=sqi_th && hr_max_abp+tolerance<VFB_th) || (ppgsqi>=sqi_th && hr_max_ppg+tolerance<VFB_th)
            alarmResult=0;
        end
    otherwise
        error(['Unknown alarm type: ' alarm_type])
end

% Write result to answers.txt
fid = fopen(answers, 'a');
if (fid == -1)
    error('Could not open answer file');
end

% Get base name of record (without directories)
i = strfind(recordName, filesep);
if (~isempty(i))
    basename = recordName(i(end)+1 : end);
else
    basename = recordName;
end

fprintf(fid, '%s,%d\n', basename, alarmResult);
fclose(fid);

end

%%%%%%%%%%%% Helper Functions %%%%%%%%%%%%%%%%%%%%%
function ind=get_index(description,pattern)
M=length(description);
tmp_ind=strfind(description,pattern);
ind=[];
for m=1:M
    if(~isempty(tmp_ind{m}))
        ind(end+1)=m;
    end
end
end
