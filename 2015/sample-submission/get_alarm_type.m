function alarm_type=get_alarm_type(recordName)
% Read header file for alarm_type

alarm_type_info = {'Asystole','Extreme_Bradycardia','Extreme_Tachycardia','Ventricular_Tachycardia','Ventricular_Fibrillation'};

fid = fopen([recordName '.hea'],'r');
c = textscan(fid,'%s');
c = c{1};

for i=1:5
    if sum(ismember(c,alarm_type_info{i}))
        alarm_type = i;
        return;
    end
end