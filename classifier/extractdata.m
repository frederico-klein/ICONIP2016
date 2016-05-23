function [data, lab] = extractdata(structure, typetype, inputlabels,varargin)
for i = 1:length(varargin)
    switch varargin{i}
        case 'wantvelocity'
            WANTVELOCITY = true;
        case 'rand'
            RANDSQE = true;
        case 'novelocity'
            WANTVELOCITY = true;
        case 'seq'
            RANDSQE = false;
        otherwise
            error('unexpected argument')
    end
end
dbgmsg('Extracting data from skeleton structure',1)
if WANTVELOCITY
    dbgmsg('Constructing long vectors with velocity data as well',1)
end
Data = [];
ends = [];
if strcmp(typetype,'act')
    [labelZ,~] = alllabels(structure,inputlabels);
elseif strcmp(typetype,'act_type')
    [~, labelZ] = alllabels(structure,inputlabels);
else
    error('strange type')
end
lab = sort(labelZ);
Y = [];
if RANDSQE
    randseq = randperm(length(structure));
else
    randseq = 1:length(structure);
end
for i = randseq 
    Data = cat(3, Data, structure(i).skel);
    Y = cat(2, Y, repmat(whichlab(structure(i),lab,typetype),1,size(structure(i).skel,3)));
    ends = cat(2, ends, size(structure(i).skel,3));
end
if WANTVELOCITY
    Data_vel = [];
    for i = randseq 
        Data_vel = cat(3, Data_vel, structure(i).vel);        
    end
    Data = cat(1,Data, Data_vel);
end
vectordata = [];
for i = 1:length(Data)
    vectordata = cat(2,vectordata, [Data(:,1,i); Data(:,2,i); Data(:,3,i)]);
end
data.data = vectordata;
data.y = Y;
data.ends = ends;
end
function [lab, biglab] = alllabels(st,lab)
biglab = lab;
if isfield(st,'act')&&isfield(st,'act_type')
    for i = 1:length(st) 
        cu = strfind(lab, st(i).act);
        if isempty(lab)||isempty(cell2mat(cu))
            lab = [{st(i).act}, lab];
            biglab = [{[st(i).act st(i).act_type]}, biglab];
        end
        bgilab = [st(i).act st(i).act_type];
        cu = strfind(biglab, bgilab);
        if isempty(biglab)||isempty(cell2mat(cu))
            biglab = [{bgilab}, biglab];
        end
    end
end
if isfield(st,'act_type')
    for i = 1:length(st)
        cu = strfind(biglab, st(i).act_type);
        if isempty(biglab)||isempty(cell2mat(cu))
            biglab = [{st(i).act_type}, biglab];
        end
         
    end
elseif isfield(st,'act')
    for i = 1:length(st)
        cu = strfind(lab, st(i).act);
        if isempty(lab)||isempty(cell2mat(cu))
            lab = [{st(i).act}, lab];
        end
    end     
else
    error('No action fields in data structure.')
end
end
function outlab = whichlab(st,lb,tt)
numoflabels = size(lb,2);
switch tt
    case 'act_type'
        if isfield(st, 'act')
            comp_act = [st.act st.act_type];
        else
            comp_act = st.act_type;
        end
    case 'act'
        comp_act = st.act;
    otherwise
        error('Unknown classification type!')
end
for i = 1:numoflabels
    if strcmp(lb{i},comp_act)
        lab = i;
    end
end
outlab = zeros(numoflabels,1);
outlab(lab) = 1;
end
