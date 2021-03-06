function PckVal = loadPackets(device,path)
[SLASH, ~] = OS_VARS();
n = 22; % No. of columns of T
fid = fopen(strcat(path,SLASH,'Shimmer',SLASH,'Packets',device,'.bin'),'r');    
B = fread(fid,'uint8');
fclose(fid);
BB = reshape(B, n,[]);
PckVal = permute(BB,[2,1]); 