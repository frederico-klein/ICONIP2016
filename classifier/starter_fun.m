function simvar = starter_fun()
global VERBOSE LOGIT TEST
VERBOSE = true;
LOGIT = true;
%%%% STARTING MESSAGES PART FOR THIS RUN
dbgmsg('=======================================================================================================================================================================================================================================')
dbgmsg('Running starter script')
dbgmsg('=======================================================================================================================================================================================================================================')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Each trial is trained on freshly partitioned/ generated data, so that we
% have an unbiased understanding of how the chained-gas is classifying.
%
% They are generated in a way that you can use nnstart to classify them and
% evaluated how much better (or worse) a neural network or some other
% algorithm can separate these datasets. Also, the data for each action
% example has different length, so the partition of datapoints is not
% equitative (there will be some fluctuation in the performance of putting
% every case in one single bin) and it will not be the same in validation
% and training sets. If you want to have the same dataset for each run,
% then use find and change the variable simvar.generatenewdataset to false.

env = set_environment; % load environment variables. you will have to change this function to your own setup

%creates a structure with the results of different trials
env.cstfilename=strcat(env.wheretosavestuff,env.SLASH,'cst.mat');
if exist(env.cstfilename,'file')
    load(env.cstfilename,'simvar')
end
if ~exist('simvar','var')
    simvar = struct();
else
    simvar(end+1).nodes = [];%cst(1);
end

%% Choose dataset

simvar(end).generatenewdataset = false;
simvar(end).datasettype = 'tstv2'; % datasettypes are 'CAD60', 'tstv2' and 'stickman'
simvar(end).sampling_type = 'type2';
simvar(end).activity_type = 'act'; %'act_type' or 'act'
simvar(end).prefilter = 'none'; % 'filter', 'none', 'median?'
simvar(end).labels_names = []; % necessary so that same actions keep their order number
simvar(end).TrainSubjectIndexes = [];%[9,10,11,4,8,5,3,6]; %% comment these out to have random new samples
simvar(end).ValSubjectIndexes = [];%[1,2,7];%% comment these out to have random new samples
simvar(end).randSubjEachIteration = true;
simvar(end).extract = {'seq', 'wantvelocity'};
simvar(end).preconditions = {'highhips', 'normal', 'intostick2', 'mirrorx'};
simvar(end).trialdataname = strcat('skel',simvar(end).datasettype,'_',simvar(end).sampling_type,simvar(end).activity_type,'_',simvar(end).prefilter, [simvar(end).extract{:}],[simvar(end).preconditions{:}]);
simvar(end).trialdatafile = strcat(env.wheretosavestuff,env.SLASH,simvar(end).trialdataname,'.mat');
%% Setting up runtime variables

% set other additional simulation variables

TEST = false; % set to false to actually run it
simvar(end).PARA = 0;
simvar(end).P = 1;
simvar(end).NODES_VECT = [1000];
simvar(end).MAX_EPOCHS_VECT = [10];
simvar(end).ARCH_VECT = [1];
simvar(end).MAX_NUM_TRIALS = 1;
simvar(end).MAX_RUNNING_TIME = 1;3600*10; %%% in seconds, will stop after this

% set parameters for gas:

params.MAX_EPOCHS = [];
params.removepoints = true;
params.PLOTIT = false;
params.RANDOMSTART = true; % if true it overrides the .startingpoint variable
params.RANDOMSET = false; % if true, each sample (either alone or sliding window concatenated sample) will be presented to the gas at random
params.savegas.resume = false; 
params.savegas.save = false;
params.savegas.path = env.wheretosavestuff;
params.savegas.parallelgases = true;
params.savegas.parallelgasescount = 0;
params.savegas.accurate_track_epochs = true;
params.savegas.P = simvar(end).P;
params.startingpoint = [1 2];
params.amax = 50; %greatest allowed age
params.nodes = []; %maximum number of nodes/neurons in the gas
params.en = 0.006; %epsilon subscript n
params.eb = 0.2; %epsilon subscript b
params.gamma = 4; % for the denoising function
params.plottingstep = 0; % zero will make it plot only the end-gas

%Exclusive for gwr
params.STATIC = true;
params.at = 0.95; %activity threshold
params.h0 = 1;
params.ab = 0.95;
params.an = 0.95;
params.tb = 3.33;
params.tn = 3.33;

%Exclusive for gng
params.age_inc                  = 1;
params.lambda                   = 3;
params.alpha                    = .5;     % q and f units error reduction constant.
params.d                           = .99;   % Error reduction factor.

%% Begin loop
for architectures = simvar(end).ARCH_VECT
    for NODES = simvar(end).NODES_VECT
        for MAX_EPOCHS = simvar(end).MAX_EPOCHS_VECT
            simvar(end).TEST = TEST;
            simvar(end).arch = architectures;
            simvar(end).NODES =  NODES;
            simvar(end).MAX_EPOCHS = MAX_EPOCHS;
            
            params.MAX_EPOCHS = simvar(end).MAX_EPOCHS;
            params.nodes = simvar(end).NODES; %maximum number of nodes/neurons in the gas
            
            %% Loading data
            datasetmissing = false;
            if ~exist(simvar(end).trialdatafile, 'file')&&~simvar(end).generatenewdataset
                dbgmsg('There is no data on the specified location. Will generate new dataset.',1)
                datasetmissing = true;
            end
            if simvar(end).generatenewdataset||datasetmissing
                [allskel1, allskel2, simvar(end).TrainSubjectIndexes, simvar(end).ValSubjectIndexes] = generate_skel_data(simvar(end).datasettype, simvar(end).sampling_type, simvar(end).TrainSubjectIndexes, simvar(end).ValSubjectIndexes, simvar(end).randSubjEachIteration);
                [allskel1, allskel2] = conformactions(allskel1,allskel2, simvar(end).prefilter);
                [data.train, simvar(end).labels_names] = extractdata(allskel1, simvar(end).activity_type, simvar(end).labels_names,simvar(end).extract{:});
                [data.val, simvar(end).labels_names] = extractdata(allskel2, simvar(end).activity_type, simvar(end).labels_names,simvar(end).extract{:});
                [data, params.skelldef] = conformskel(data, simvar(end).preconditions{:});
                simvar(end).trialdatafile = savefilesave(simvar(end).trialdataname, {data, simvar,params},env);
                %save(simvar(end).trialdataname,'data', 'simvar','params');
                dbgmsg('Training and Validation data saved.')
                clear datasetmissing
            else
                loadedtrial = loadfileload(simvar(end).trialdataname,env);
                data = loadedtrial.data;
                params.skelldef = loadedtrial.params.skelldef;
                simvar(end).generatenewdataset = false;
            end
            %%%%% to use nnstart/nntool, stop here and separate the parts
            %%%%% of the data structure into individual variables
            simvar(end).datainputvectorsize = size(data.train.data,1);
            %% Classifier structure definitions
            
            simvar(end).allconn = allconnset(simvar(end).arch, params);
            
            
            %% Setting up different parameters for each of parallel trial
            % I intended for this to be possible, but was never used. 
            for i = 1:simvar(end).P
                simvar(end).paramsZ(i) = params;
            end           
            
            clear a
            b = [];
            
            if ~TEST 
                starttime = tic;
                while toc(starttime)< simvar(end).MAX_RUNNING_TIME
                    if length(b)> simvar(end).MAX_NUM_TRIALS
                        break
                    end
                    if simvar(end).PARA
                        spmd(simvar(end).P)
                            a(labindex).a = executioncore_in_starterscript(simvar(end).paramsZ(labindex),simvar(end).allconn, data);
                        end
                        %b = cat(2,b,a.a);
                        for i=1:length(a)
                            c = a{i};
                            a{i} = [];
                            b = [c.a b];
                        end
                        clear a c
                        a(1:simvar(end).P) = struct();
                    else
                        for i = 1:simvar(end).P
                            a(i).a = executioncore_in_starterscript(simvar(end).paramsZ(i),simvar(end).allconn, data);
                        end
                        b = cat(2,b,a.a);
                        clear a
                        a(1:simvar(end).P) = struct();
                    end
                end
            else
                b = executioncore_in_starterscript(simvar(end).paramsZ(1),simvar(end).allconn, data);
            end
            
            simvar(end).metrics = gen_cst(b); 
            save(strcat(env.wheretosavestuff,env.SLASH,'cst.mat'),'simvar')
            
            savevar = strcat('b',num2str(simvar(end).NODES),'_', num2str(params.MAX_EPOCHS),'epochs',num2str(size(b,2)), simvar(end).sampling_type, simvar(end).datasettype, simvar(end).activity_type);
            eval(strcat(savevar,'=simvar(end);'))
            simvar(end).savesave = savefilesave(savevar, simvar(end),env);
            dbgmsg('Trial saved in: ',simvar(end).savesave,1)
            simvar(end+1) = simvar(end);
        end
        clear b
        clock
    end
end
simvar(end) = [];
end
function savesave = savefilesave(filename, savevar,env)
global TEST
ver = 1;
savesave = strcat(env.wheretosavestuff,env.SLASH,filename,'.mat');
while exist(savesave,'file')
    savesave = strcat(env.wheretosavestuff,env.SLASH,filename,'[ver(',num2str(ver),')].mat');
    ver = ver+1;
end
if ~TEST
    if iscell(savevar)&&(length(savevar)==3) % hack
        data = savevar{1};
        simvar = savevar{2};
        params = savevar{3};
        save(savesave, 'data', 'simvar','params')
    else
        save(savesave,'savevar')
    end
    dbgmsg('Saved file:',savesave,1)
end
end
function loadload = loadfileload(filename,env)
ver = 0;
loadfile = strcat(env.wheretosavestuff,env.SLASH,filename,'.mat');
while exist(loadfile,'file')
    ver = ver+1;
    loadfile = strcat(env.wheretosavestuff,env.SLASH,filename,'[ver(',num2str(ver),')].mat');
end
if ver == 1
    loadfile = strcat(env.wheretosavestuff,env.SLASH,filename,'.mat');
else
    ver = ver - 1;
    loadfile = strcat(env.wheretosavestuff,env.SLASH,filename,'[ver(',num2str(ver),')].mat');
end
loadload = load(loadfile);
dbgmsg('Loaded file:',loadfile,1)
end
function allconn = allconnset(n, params)
allconn_set = {...
    {... %%%% ARCHITECTURE 1
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[1 0],params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',[1 0],params}...
    {'gwr3layer',   'gwr',{'gwr1layer'},              'pos',[3 2],params}...
    {'gwr4layer',   'gwr',{'gwr2layer'},              'vel',[3 2],params}...
    {'gwrSTSlayer', 'gwr',{'gwr3layer','gwr4layer'},  'all',[3 2],params}...
    }...
    {...%%%% ARCHITECTURE 2
    {'gng1layer',   'gng',{'pos'},                    'pos',[1 0],params}...
    {'gng2layer',   'gng',{'vel'},                    'vel',[1 0],params}...
    {'gng3layer',   'gng',{'gng1layer'},              'pos',[3 2],params}...
    {'gng4layer',   'gng',{'gng2layer'},              'vel',[3 2],params}...
    {'gngSTSlayer', 'gng',{'gng4layer','gng3layer'},  'all',[3 2],params}...
    }...
    {...%%%% ARCHITECTURE 3
    {'gng1layer',   'gng',{'pos'},                    'pos',[1 0],params}...
    {'gng2layer',   'gng',{'vel'},                    'vel',[1 0],params}...
    {'gng3layer',   'gng',{'gng1layer'},              'pos',[3 0],params}...
    {'gng4layer',   'gng',{'gng2layer'},              'vel',[3 0],params}...
    {'gngSTSlayer', 'gng',{'gng4layer','gng3layer'},  'all',[3 0],params}...
    }...
    {...%%%% ARCHITECTURE 4
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[1 0],params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',[1 0],params}...
    {'gwr3layer',   'gwr',{'gwr1layer'},              'pos',[3 0],params}...
    {'gwr4layer',   'gwr',{'gwr2layer'},              'vel',[3 0],params}...
    {'gwrSTSlayer', 'gwr',{'gwr3layer','gwr4layer'},  'all',[3 0],params}...
    }...
    {...%%%% ARCHITECTURE 5
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[1 2 3],params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',[1 2 3],params}...
    {'gwr3layer',   'gwr',{'gwr1layer'},              'pos',[3 2],params}...
    {'gwr4layer',   'gwr',{'gwr2layer'},              'vel',[3 2],params}...
    {'gwrSTSlayer', 'gwr',{'gwr3layer','gwr4layer'},  'all',[3 2],params}...
    }...
    {...%%%% ARCHITECTURE 6
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[3 4 2],params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',[3 4 2],params}...
    {'gwrSTSlayer', 'gwr',{'gwr1layer','gwr2layer'},  'all',[3 2],params}...
    }...
    {...%%%% ARCHITECTURE 7
    {'gwr1layer',   'gwr',{'all'},                    'all',[3 2], params}...
    {'gwr2layer',   'gwr',{'gwr1layer'},              'all',[3 2], params}...
    }...
    {...%%%% ARCHITECTURE 8
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[3 2], params}... %% now there is a vector where q used to be, because we have the p overlap variable...
    }...
    {...%%%% ARCHITECTURE 9
    {'gwr1layer',   'gwr',{'pos'},                    'pos',3,params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',3,params}...
    {'gwr3layer',   'gwr',{'gwr1layer'},              'pos',3,params}...
    {'gwr4layer',   'gwr',{'gwr2layer'},              'vel',3,params}...
    {'gwr5layer',   'gwr',{'gwr3layer'},              'pos',3,params}...
    {'gwr6layer',   'gwr',{'gwr4layer'},              'vel',3,params}...
    {'gwrSTSlayer', 'gwr',{'gwr6layer','gwr5layer'},  'all',3,params}
    }...
    {... %%%% ARCHITECTURE 10
    {'gwr1layer',   'gwr',{'pos'},                    'pos',[1 0],params}...
    {'gwr2layer',   'gwr',{'vel'},                    'vel',[1 0],params}...
    {'gwrSTSlayer', 'gwr',{'gwr1layer','gwr2layer'},  'all',[3 2],params}...
    }...
    };
allconn = allconn_set{n};
end
function a = executioncore_in_starterscript(paramsZ,allconn, data)
global TEST
n = randperm(size(data.train.data,2)-3,2); % -(q-1) necessary because concatenation reduces the data size. Sometimes this fails
paramsZ.startingpoint = [n(1) n(2)];
pallconn = allconn;
pallconn{1,1}{1,6} = paramsZ;
%[a.sv, a.mt] = starter_sc(data, pallconn, 1);
if TEST
    dbgmsg('TEST RUN. Generating sham output data. Data will not be saved.',1)
    confconf = struct('val','val', 'train', '');
    ouout = struct('accumulatedepochs',0);
    for i =1:4
        for j =1:5
            a.mt(i,j) = struct('conffig', 'figset','confusions', confconf,'conffvig', 'figset','outparams',ouout);
        end
    end
    
else
    [~, a.mt] = starter_sc(data, pallconn);
end
end
function [savestructure, metrics] = starter_sc(savestructure, allconn)
%% starter_sc
% This is the main function to run the chained classifier, label and
% generate confusion matrices and recall, precision and F1 values for the
% skeleton classifier of activities using an architecture of chained neural
% gases on skeleton activities data (the STS V2 Dataset). This work is an
% attempt to implement Parisi, 2015's paper.

%%
global VERBOSE LOGIT
VERBOSE = true;
LOGIT = true;
%%% making metrics structure

metrics = struct('confusions',[],'conffig',[],'outparams',[]);
%%%% building arq_connect
arq_connect(1:length(allconn)) = struct('name','','method','','sourcelayer','', 'layertype','','q',[1 0],'params',struct());
for i = 1:length(allconn)
    arq_connect(i).name = allconn{i}{1};
    arq_connect(i).method = allconn{i}{2};
    arq_connect(i).sourcelayer = allconn{i}{3};
    arq_connect(i).layertype = allconn{i}{4};
    arq_connect(i).q = allconn{i}{5};
    arq_connect(i).params = allconn{i}{6};
    arq_connect(i).params.q = arq_connect(i).q;
end
inputs = struct('input_clip',[],'input',[],'input_ends',[],'oldwhotokill',{}, 'index', {});
gas_data = struct('name','','class',[],'y',[],'inputs',inputs,'bestmatch',[],'bestmatchbyindex',[],'whotokill',{});
gas_methods(1:length(arq_connect)) = struct('name','','edges',[],'nodes',[],'fig',[],'nodesl',[]); %bestmatch will have the training matrix for subsequent layers
savestructure.gas = gas_methods;
savestructure.train.indexes = [];
savestructure.train.gas = gas_data;
savestructure.val.indexes = [];
savestructure.val.gas = gas_data;

for i = 1:length(savestructure) 
    savestructure.figset = {};
end

%% Gas-chain Classifier
% This part executes the chain of interlinked gases. Each iteration is one
% gas, and currently it works as follows:
% 1. Function setinput() chooses based on the input defined in allconn
% 2. Run either a Growing When Required (gwr) or Growing Neural Gas (GNG)
% on this data
% 3. Generate matrix of best matching units to be used by the next gas
% architecture
% 4. Finds and removes data that cannot be accurately described by our N 
% gas nodes
dbgmsg('Starting chain structure for GWR and GNG for nodes:',num2str(labindex),1)

for j = 1:length(arq_connect)
    [savestructure, savestructure.train] = gas_method(savestructure, savestructure.train,'train', arq_connect(j),j, size(savestructure.train.data,1)); % I had to separate it to debug it.
    metrics(j).outparams = savestructure.gas(j).outparams;
    [savestructure, savestructure.val ]= gas_method(savestructure, savestructure.val,'val', arq_connect(j),j, size(savestructure.train.data,1));
end


%% Gas Outcomes
%  Shows how well the dataset is described by the current gas

for j = 1:length(arq_connect)
    if arq_connect(j).params.PLOTIT
        figure
        subplot (1,length(arq_connect),j)
        hist(savestructure.gas(j).outparams.graph.errorvect)
        title((savestructure.gas(j).name))
    end
end
%% Labelling
% The current labelling procedure for both the validation and training
% datasets. As of this moment I label all the gases to see how adding each
% part increases the overall performance of the structure, but since this
% is slow, the variable whatIlabel can be changed to contain only the last
% gas.
%
% The labelling procedure is simple. It basically picks the label of the
% closest point and assigns to that. In a sense the gas can be seen as a
% spacial (as opposed to temporal) filter.
dbgmsg('Labelling',num2str(labindex),1)

whatIlabel = 1:length(savestructure.gas); %change this series for only the last value to label only the last gas

%%
% Specific part on what I want to label
for j = whatIlabel
    dbgmsg('Applying labels for gas: ''',savestructure.gas(j).name,''' (', num2str(j),') for process:',num2str(i),1)
    [savestructure.train.gas(j).class, savestructure.val.gas(j).class,savestructure.gas(j).nodesl ] = labeller(savestructure.gas(j).nodes, savestructure.train.gas(j).bestmatchbyindex,  savestructure.val.gas(j).bestmatchbyindex, savestructure.train.gas(j).inputs.input, savestructure.train.gas(j).y);
end

%% Displaying multiple confusion matrices for GWR and GNG for nodes
% This part creates the matrices that can later be shown with the
% plotconfusion() function.

savestructure.figset = {}; %% you should clear the set first if you want to rebuild them
dbgmsg('Displaying multiple confusion matrices for GWR and GNG for nodes:',num2str(labindex),1)

for j = whatIlabel
    [~,metrics(j).confusions.val,~,~] = confusion(savestructure.val.gas(j).y,savestructure.val.gas(j).class);
    [~,metrics(j).confusions.train,~,~] = confusion(savestructure.train.gas(j).y,savestructure.train.gas(j).class);
    
    dbgmsg(savestructure.gas(j).name,' Confusion matrix on this validation set:',writedownmatrix(metrics(j).confusions.val),1)
    savestructure.gas(j).fig.val =   {savestructure.val.gas(j).y,     savestructure.val.gas(j).class,  strcat(savestructure.gas(j).name,savestructure.gas(j).method,'V')};
    savestructure.gas(j).fig.train = {savestructure.train.gas(j).y,   savestructure.train.gas(j).class,strcat(savestructure.gas(j).name,savestructure.gas(j).method,'T')};
    %savestructure.figset = [savestructure.figset, savestructure.gas(j).fig.val, savestructure.gas(j).fig.train];
    %%%
    metrics(j).conffig = savestructure.gas(j).fig;
end

%% Actual display of the confusion matrices:
metitems = [];
for j = whatIlabel
if arq_connect(j).params.PLOTIT
    metitems = [metitems j*arq_connect(j).params.PLOTIT];
end    
end
if ~isempty(metitems)
figure
plotconf([metrics(metitems)])
end
%plotconf(savestructure.figset{:})
figure
plotconfusion(savestructure.gas(end).fig.val{:})

end
function [sst, sstv] = gas_method(sst, sstv, vot, arq_connect,j, dimdim)
%% Gas Method
% This is a function to go over a gas of the classifier, populate it with the apropriate input and generate the best matching units for the next layer.
%% Setting up some labels
sst.gas(j).name = arq_connect.name;
sst.gas(j).method = arq_connect.method;
sst.gas(j).layertype = arq_connect.layertype;
arq_connect.params.layertype = arq_connect.layertype;

%% Choosing the right input for this layer
% This calls the function set input that chooses what will be written on
% the .inputs variable. It also handles the sliding window concatenations
% and saves the .input_ends properties, so that this can be done
% recursevely.

dbgmsg('Working on gas: ''',sst.gas(j).name,''' (', num2str(j),') with method: ',sst.gas(j).method ,' for process:',num2str(labindex),1)

[sstv.gas(j).inputs.input_clip, sstv.gas(j).inputs.input, sstv.gas(j).inputs.input_ends, sstv.gas(j).y, sstv.gas(j).inputs.oldwhotokill, sstv.gas(j).inputs.index, sstv.gas(j).inputs.awk ]  = setinput(arq_connect, sst, dimdim, sstv); %%%%%%

%%
% After setting the input, we can actually run the gas, either a GNG or the
% GWR function we wrote.
if strcmp(vot, 'train')
    %DO GNG OR GWR
    [sst.gas(j).nodes, sst.gas(j).edges, sst.gas(j).outparams] = gas_wrapper(sstv.gas(j).inputs.input_clip,arq_connect);
end
dbgmsg('Finished working on gas: ''',sst.gas(j).name,''' (', num2str(j),') with method: ',sst.gas(j).method ,'.Num of nodes reached:',num2str(sst.gas(j).outparams.graph.nodesvect(end)),' for process:',num2str(labindex),1)

%% Best-matching units
% The last part is actually finding the best matching units for the gas.
% This is a simple procedure where we just find from the gas units (nodes
% or vectors, as you wish to call them), which one is more like our input.
% It is a filter of sorts, and the bestmatch matrix is highly repetitive.

dbgmsg('Finding best matching units for gas: ''',sst.gas(j).name,''' (', num2str(j),') for process:',num2str(labindex),1)
[~, sstv.gas(j).bestmatchbyindex] = genbestmmatrix(sst.gas(j).nodes, sstv.gas(j).inputs.input, arq_connect.layertype, arq_connect.q); %assuming the best matching node always comes from initial dataset!

%% Post-conditioning function
%Currently this is the noise removing function. Perhaps in the future other
%ideas may be tried.
if arq_connect.params.removepoints
    dbgmsg('Flagging noisy input for removal from gas: ''',sst.gas(j).name,''' (', num2str(j),') with points with more than',num2str(arq_connect.params.gamma),' standard deviations, for process:',num2str(labindex),1)
    sstv.gas(j).whotokill = removenoise(sst.gas(j).nodes, sstv.gas(j).inputs.input, sstv.gas(j).inputs.oldwhotokill, arq_connect.params.gamma, sstv.gas(j).inputs.index);
else
    dbgmsg('Skipping removal of noisy input for gas:',sst.gas(j).name)
end
end
