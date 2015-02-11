%This script will generate the validation set that will be used for
%cross-checking by the PhysionNet servers.
%
%In order to be compatible with the testing environment,
%you should have the training set located at the subdirectory the top
%directory of where this file unzips (ie, where challenge.m is located)
%
% Once this script is run, the generated annotation files when then be moved to % ./challenge/2015/set-p/ (or .\challenge\20145set-p\ in Windows).
%
% This location is where the scoring server expects the validating annotations % to reside.
%
% This script was only tested in MATLAB (we have not tested in Octave).
%
%
%         Written by Ikaro Silva January 27, 2015.
%         Last Modified:
%
%

clear all;close all;clc
data_dir=[pwd filesep];

%Add the function on this directory to the MATLAB path
%This is not permanent. This change is only valid for this session of
%MATLAB (will reset once MATLAB is restarted).
addpath(pwd)

if(exist('OCTAVE_VERSION'))
    more off %this seems necessary in order to get back the screen in Octave, but we have not tested this script on Octave yet.
end

%Check for previous files before starting test
answers=dir(['answers.txt']);
if(~isempty(answers))
    while(1)
        display(['Found previous answer sheet file in:' pwd])
        cont=input('Delete it (Y/N/Q)?','s');
        if(strcmp(cont,'Y') || strcmp(cont,'N') || strcmp(cont,'Q'))
            if(strcmp(cont,'Q'))
                display('Exiting script!!')
                return;
            end
            break;
        end
    end
    if(strcmp(cont,'Y'))
        display('Removing previous answer sheet.')
        delete(answers.name);
    end
end

fprintf('Generating validation set, please wait...\n')
fid=fopen([data_dir 'ALARMS'],'r');
if(fid ~= -1)
    RECLIST=textscan(fid,'%s %s %d','Delimiter',',');
    fclose(fid);
else
    error('Could not open ALARMS.txt for scoring. Exiting...')
end

RECORDS=RECLIST{1};
ALARMS=RECLIST{2};
N=length(RECORDS);
results=zeros(N,1);

total_time=0;
for i=1:N
    fname=RECORDS{i};
    tic;
    display(['results(' num2str(i) ')=challenge(''' data_dir fname ''','''  ALARMS{i} ''');'])
    try
        results(i)=challenge([data_dir fname],ALARMS{i});
    catch
        warning(lasterr)
    end
    total_time=total_time+toc;
    if(~mod(i,10))
        fprintf(['---Processed ' num2str(i) ' out of ' num2str(N) ' records.\n'])
    end
end

averageTime = total_time/N;
fprintf(['Generation of validation set completed !! Total time= ' ...
    num2str(total_time) ' average time= ' num2str(averageTime) '\n'])
fprintf(['Answer file created at : ' pwd 'answers.txt. Processing completed!!'])
fprintf(['**Running : score2015Challenge.m to get score stats on your entry on the training set....\n'])
score2015Challenge

fprintf(['**Scoring complete.\n'])
while(1)
    display(['Do you want to package your entry for scoring?'])
    cont=input('(Y/N/Q)?','s');
    if(strcmp(cont,'Y') || strcmp(cont,'N') || strcmp(cont,'Q'))
        if(strcmp(cont,'Q'))
            display('Exiting!!')
            return;
        end
        break;
    end
end

if(strcmp(cont,'Y'))
    display(['Packaging your entry (excluding any subdirectories) to:' pwd filesep 'entry.zip'])
    %Delete any files if they existed previously
    delete('entry.zip')
    %This will not package any sub-directories !
    zip('entry.zip',{'*.m','*.txt','*.sh'});
end




