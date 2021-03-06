function [allskel1, allskel2, allskeli1, allskeli2] = generate_skel_data(varargin)
if nargin<2
    error('not enough arguments')
end
dataset = varargin{1};
sampling_type = varargin{2};
if nargin>2
    allskeli1 = varargin{3};
end
if nargin>3
    allskeli2 = varargin{4};
end
if isempty(allskeli1)||isempty(allskeli2)||varargin{5} 
    clear allskeli1
    clear allskeli2
end
switch dataset
    case 'CAD60'
        loadfun = @readcad60;
        datasize = 4;
    case 'tstv2'
        loadfun = @LoadDataBase;
        datasize = 11;
    case 'stickman'
        loadfun = @generate_falling_stick;
        datasize = 20; 
        if strcmp(sampling_type,'type1')
            dbgmsg('Sampling type1 not implemented for falling_stick!!! Using type2',1)
            sampling_type = 'type2';
        end
    otherwise
        error('Unknown database.')
end
if exist('allskeli1','var')
    if any(allskeli1>datasize)
        error('Index 1 is out of range for selected dataset.')
    end
end
if exist('allskeli2','var')
    if any(allskeli2>datasize)
        error('Index 2 is out of range for selected dataset.')
    end
end
dbgmsg('Generating random datasets for training and validation')
if exist('allskeli1','var')
    dbgmsg('Variable allskeli1 is defined. Will skip randomization.')
end
if strcmp(sampling_type,'type1')
    allskel = loadfun(1:datasize);
    if ~exist('allskeli1','var')
        allskeli1 = randperm(length(allskel),fix(length(allskel)*.8)); 
    end
    allskel1 = allskel(allskeli1);
    if ~exist('allskeli2','var')
        allskeli2 = setdiff(1:length(allskel),allskeli1); 
    end
    allskel2 = allskel(allskeli2);
end
if strcmp(sampling_type,'type2')
    if ~exist('allskeli1','var')
        allskeli1 = randperm(datasize,fix(datasize*.8)); 
    end
    allskel1 = loadfun(allskeli1(1)); 
    for i=2:length(allskeli1)
        allskel1 = cat(2,loadfun(allskeli1(i)),allskel1 ); 
    end
    allskeli2 = setdiff(1:datasize,allskeli1); 
    allskel2 = loadfun(allskeli2(1));
    for i=2:length(allskeli2)
        allskel2 = cat(2,loadfun(allskeli2(i)),allskel2 ); 
    end
end