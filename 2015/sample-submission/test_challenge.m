fid = fopen('Records','r');
c = textscan(fid,'%s');
for i=1:length(c{1})
    c{1}{i}
    challenge(c{1}{i});
end
