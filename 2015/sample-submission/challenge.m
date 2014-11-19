function challenge(recordList)
%
% challenge(recordName)
%
% Sample entry for the 2015 PhysioNet/CinC Challenge.
% This function should takes one parameter:
%
% input:
%   recordList
%       String specifying the record list file to process
%
% This function has no output arguments, its writes an "challenge-answers.txt" ascii file
% at the current directory. 
%
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
% Version 0.3
%
% See also: RDSAMP, RDANN, WRANN, GQRS, ECGPUWAVE, SQRS, WQRS, WABP
%
% Written by Qiao Li, November 10, 2014.
% Last Modified: November 19, 2014
%
%
%
% %Example using training data- 
% challenge('Records')
%

fid = fopen(recordList,'r');
c = textscan(fid,'%s');
fclose(fid);

fid = fopen('challenge-answers.txt','w');

for i=1:length(c{1})
    recordName = c{1}{i};
    fprintf('Processing %s ...\n',recordName);
    
    alarm_type=get_alarm_type(recordName);
    %   alarm_type
    %       1:Asystole
    %       2:Bradycardia
    %       3:Tachycardia
    %       4:Ventricular Tachycardia
    %       5:Ventricular Fibrillation

    %Get all ECG, blood pressure and photoplethysmogram signals
    [tm,signal,Fs,siginfo]=rdmat(recordName);

    description=squeeze(struct2cell(siginfo));
    description=description(4,:);

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
    if(~isempty(abp_ind))
       ann_abp=wabp(signal(:,abp_ind),0,1);
       % Analyze the signal quality index of ABP using jSQI
       if ~isempty(ann_abp)
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

    % set valid data segment for decision making, 10s before and 5 after the
    % alarm ???
    N_d=Fs(1)*5*60+Fs(1)*5;
    N0_d=N_d-Fs(1)*15+1;

    % select the beats in the segment
    n_abp_beats=intersect(find(ann_abp>=N0_d),find(ann_abp<=N_d));
    n_ppg_beats=intersect(find(ann_ppg>=N0_d),find(ann_ppg<=N_d));

    hr_max_abp=NaN;
    hr_min_abp=NaN;
    max_rr_abp=NaN;
    hr_max_ppg=NaN;
    hr_min_ppg=NaN;
    max_rr_ppg=NaN;

    % calculate the heart rate
    if length(n_abp_beats)>=2
        hr_max_abp=60*Fs(1)/min(diff(ann_abp(n_abp_beats)));
        hr_min_abp=60*Fs(1)/max(diff(ann_abp(n_abp_beats)));

        max_rr_abp=max(diff(ann_abp(n_abp_beats)))/Fs(1);
    end
    if length(n_ppg_beats)>=2
        hr_max_ppg=60*Fs(1)/min(diff(ann_ppg(n_ppg_beats)));
        hr_min_ppg=60*Fs(1)/max(diff(ann_ppg(n_ppg_beats)));

        max_rr_ppg=max(diff(ann_ppg(n_ppg_beats)))/Fs(1);
    end


    % calculate the signal quality index
    if ~isempty(ann_abp)
        abpsqi=1-sum(sum(BEATQ(n_abp_beats,:)))/numel(BEATQ(n_abp_beats,:));
    else
        abpsqi=0;
    end
    if ~isempty(ann_ppg)
        ppgsqi=mean(psqi(n_ppg_beats));
    else
        ppgsqi=0;
    end

    Alarm = 1;

    % SQI threshold = 0.9 ???
    sqi_th = 0.9;

    % Alarm threshold ???
    ASY_th = 4;
    BRA_th = 40;
    TAC_th = 140;
    VTA_th = 100;
    VFB_th = 150;

    switch alarm_type
        case 1
            % if the signal quality is good enough and the maximum RR interval
            % is less than the Asystole threshold, set the alarm as 'F'
            if (abpsqi>=sqi_th && max_rr_abp<ASY_th) || (ppgsqi>=sqi_th && max_rr_ppg<ASY_th)
                Alarm = 0;
            end
        case 2
            % if the signal quality is good enough and the minimum heart rate
            % is greater than the Bradycardia threshold, set the alarm as 'F'
            if (abpsqi>=sqi_th && hr_min_abp>BRA_th) || (ppgsqi>=sqi_th && hr_min_ppg>BRA_th)
                Alarm = 0;
            end
        case 3
            % if the signal quality is good enough and the maximum heart rate
            % is less than the Tachycardia threshold, set the alarm as 'F'
            if (abpsqi>=sqi_th && hr_max_abp<TAC_th) || (ppgsqi>=sqi_th && hr_max_ppg<TAC_th)
                Alarm = 0;
            end
        case 4
            if (abpsqi>=sqi_th && hr_max_abp<VTA_th) || (ppgsqi>=sqi_th && hr_max_ppg<VTA_th)
                Alarm = 0;
            end
        case 5
            if (abpsqi>=sqi_th && hr_max_abp<VFB_th) || (ppgsqi>=sqi_th && hr_max_ppg<VFB_th)
                Alarm = 0;
            end
    end
   
    % saving the result to challenge-answers.txt file
    fprintf(fid,'%s %1d\n',recordName,Alarm);
end

fclose(fid);

end

%%%%%%%%%%%% Helper Function %%%%%%%%%%%%%%%%%%%%%
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
