%
%
% This script will calculate the statistics of your algorithm for each type
% of alarm, based on the true answer sheet. Your final score for the
% challenge will be a function of these statistics on the hidden test set.
%
%
% This script requires that you first run generateValidationSet.m
%
%
% Written by Ikaro Silva, January 26, 2015
%            Last Modified:
%

clear all;
fid=fopen('answers.txt','r');
if(fid ~= -1)
    ANSWERS=textscan(fid,'%s %d','Delimiter',',','EmptyValue',0); %Set empty values to FALSE alarms by default
    fclose(fid);
else
    error('Could not open users answer.txt for scoring. Run the generateValidationSet.m script and try again.')
end

fid=fopen(['ALARMS'],'r');
if(fid ~= -1)
    GOLD=textscan(fid,'%s %s %d','Delimiter',',');
    fclose(fid);
else
    error('Could not open challenge/ALARMS for scoring. Exiting...')
end

N=length(GOLD{1});
%Result columnes are: true positives, false positive, false negative, true
%negatives
RECORDS=GOLD{1};
ALARMS=GOLD{2};
ALARM_TYPES=unique(ALARMS);
NTYPES=length(ALARM_TYPES);
results=zeros(NTYPES,4);
GOLD_TRUTH=GOLD{3};

%We do not assume that the Gold-standar and the Answers are sorted in the
%same order, so we search for the location of the individual records in
%ANSWER file
for n=1:N
    
    alarm_ind=strcmp(ALARMS{n},ALARM_TYPES);
    if(isempty(alarm_ind))
        error(['Unexpected alarm type: ' ALARMS{n} ' . Expected alarm types are: ' ALARM_TYPES{:} ])
    end
    
    rec_ind=strmatch(RECORDS{n},ANSWERS{1});
    if(isempty(rec_ind))
        warning(['Could not find answer for record: ' RECORDS{n} , ' setting it to a false alarm.'])
        this_answer=0;
    else
        this_answer=ANSWERS{2}(rec_ind);
    end
    if(this_answer ~=0)
        %Positive cases
        if(GOLD_TRUTH(n) == 1)
            %True positive
            results(alarm_ind,1)=results(alarm_ind,1)+1;
        else
            %False positive
            results(alarm_ind,2)=results(alarm_ind,2)+1 ;
        end
    else
        %Negative cases
        if(GOLD_TRUTH(n) == 1)
            %False negative
            results(alarm_ind,3)=results(alarm_ind,3)+1;
        else
            %True negative
            results(alarm_ind,4)=results(alarm_ind,4)+1;
        end
    end
end
total=sum(results,2);
nresults=results./repmat(total,[1 4]);
gross=sum(results)/sum(sum(results));

for n=1:NTYPES
    indent=repmat(['\t'],[1 4-round(length(ALARM_TYPES{n})/8)]);
    str=[ALARM_TYPES{n} ':' indent 'TP: %1.3f\tFP: %1.3f \tFN: %1.3f\tTN: %1.3f\n'];
    fprintf(str,nresults(n,1),nresults(n,2),nresults(n,3),nresults(n,4))
end

indent=repmat(['\t'],[1 4-round(length('Average')/8)]);
str=['Average:' indent 'TP: %1.3f\tFP: %1.3f \tFN: %1.3f\tTN: %1.3f\n'];
fprintf(str,mean(nresults(:,1)),mean(nresults(:,2)),mean(nresults(:,3)),mean(nresults(:,4)))

indent=repmat(['\t'],[1 4-round(length('Gross')/8)]);
str=['Gross:' indent 'TP: %1.3f\tFP: %1.3f \tFN: %1.3f\tTN: %1.3f\n'];
fprintf(str,gross(:,1),gross(:,2),gross(:,3),gross(:,4))


