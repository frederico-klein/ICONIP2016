function dbgmsg(varargin)
global VERBOSE
if isempty('VERBOSE')
    VERBOSE = false;
end
logfile = true; 
msg = varargin{1};
if nargin >2
    msg = strcat(varargin{1:end-1});
    VERBOSE = varargin{end};
end
if nargin >1
    VERBOSE = varargin{end};
else
   
end
if VERBOSE
    doubleprint(logfile,'[%s %f] ',date,cputime);
    a = dbstack;
    doubleprint(logfile,a(end).name);
    if length(a)>1
        for i = (length(a)-1):-1:2
            doubleprint(logfile,': ');
            doubleprint(logfile,a(i).name);
        end
    end
    doubleprint(logfile,': ');
    doubleprint(logfile,msg);
    doubleprint(logfile,'\n');
end
end
function doubleprint(varargin)
persistent logfile
global logpath LOGIT
if ~isempty('LOGIT')||LOGIT
    if isempty(logpath)
        set_environment;
    end
    logfile = fopen(logpath,'at'); 
    fprintf(logfile,varargin{2:end});
    fclose(logfile);
end
fprintf(varargin{2:end});
end
