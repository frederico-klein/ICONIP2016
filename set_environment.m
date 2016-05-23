function env = set_environment()
global logpath
try
    if ismac
		env.wheretosavestuff = '~/matlabprogs';
		env.homepath = './';
		%disp('reached ismac')
	elseif isunix
		env.wheretosavestuff = '~/matlabprogs'; 
		env.homepath = './';
		%disp('reached isunix')
    elseif ispc
        env.wheretosavestuff = '~\matlabprogs'; %must check if tilde works with windows
		env.homepath = '~\matlabprogs\';		
    end
	addpath(genpath(env.homepath)) 
catch
	disp('oh-oh')
	%open dialog box?
 	%have to see how to do it
end
logpath = strcat(env.homepath,'log.txt');
[env.SLASH, env.pathtodata] = OS_VARS();