function [conformstruc, skelldef] = conformskel(varargin )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dbgmsg('Applies preconditioning functions to both training and validation datasets',1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test = false;
skelldef = struct();
if isempty(varargin)||strcmp(varargin{1},'test')
    return
else    
    if isstruct(varargin{1})
        conformstruc = varargin{1};
        data_train = conformstruc.train.data;
        data_val = conformstruc.val.data;
        data_ytrain = conformstruc.train.y ;
        data_yval = conformstruc.val.y;        
        if isfield(conformstruc,'awk')
            awk = conformstruc.awk;
        else
            awk = ones(size(data_val,1)/6,1);
            %dbgmsg('awk not defined. considering all joints as having equal importance.',1)
        end
        lindx = 2;
    else    
    data_train = varargin{1};
    data_val = varargin{2};
    if isnumeric(varargin{3})
        awk = varargin{3};
        lindx = 4;
    elseif ischar(varargin{3})
        awk = ones(size(data_val,1)/6,1);
        lindx = 3;
    else
        error('Unknown input. ')
    end
    end
    %%% initiallize variables to make skelldef
    killdim = [];
    skelldef.length = size(data_val,1);
    skelldef.realkilldim = [];
    skelldef.elementorder = 1:skelldef.length;
    skelldef.awk.pos = repmat(awk(setdiff(1:skelldef.length/6,killdim)),3,1);
    skelldef.awk.vel = repmat(awk(setdiff(1:skelldef.length/6,killdim)),3,1);    
    %%%
    skelldef.bodyparts = genbodyparts(skelldef.length);    
    if size(data_train)~=skelldef.length
        error('data_train and data_val must have the same length.')
    end
    if any(size(awk).*[6 1]~= size(data_val(:,1)))
        %warning('wrong size for awk')
    end
    % creates the function handle cell array
    conformations = {};
    killdim = [];    
    for i =lindx:length(varargin)
        switch varargin{i}
            case 'test'
                test = true;
            case 'highhips'
                conformations = [conformations, {@highhips}];
            case 'nohips'
                conformations = [conformations, {@centerhips}];
                killdim = [killdim, skelldef.bodyparts.SpineBase];
            case 'normal'
                conformations = [conformations, {@normalize}];                
                %dbgmsg('Unimplemented normalization: ', varargin{i} ,true);
            case 'mirrorx'
                conformations = [conformations, {@mirrorx}];
            case 'mirrory'
                conformations = [conformations, {@mirrory}];
            case 'mirrorz'
                conformations = [conformations, {@mirrorz}];
            case 'mahal'
                %conformations = [conformations, {@mahal}];
                dbgmsg('Unimplemented normalization: ', varargin{i} ,true);
            case 'norotate'
                conformations = [conformations, {@norotatehips}];
                dbgmsg('WARNING, the normalization: ' , varargin{i},' is performing poorly, it should not be used.', true);
            case 'norotateshoulders'
                conformations = [conformations, {@norotateshoulders}];
                dbgmsg('WARNING, the normalization: ' , varargin{i},' is performing poorly, it should not be used.', true);
            case 'notorax'
                conformations = [conformations, {@centertorax}];
                dbgmsg('WARNING, the normalization: ' , varargin{i},' is performing poorly, it should not be used.', true);
                killdim = [killdim, skelldef.bodyparts.TORSO];
            case 'nofeet'
                conformations = [conformations, {@nofeet}]; %not sure i need this...
                killdim = [killdim, skelldef.bodyparts.RIGHT_FOOT, skelldef.bodyparts.LEFT_FOOT];
            case 'nohands'
                dbgmsg('WARNING, the normalization: ' , varargin{i},' is performing poorly, it should not be used.', true);
                killdim = [killdim, skelldef.bodyparts.RIGHT_HAND, skelldef.bodyparts.LEFT_HAND];
            case 'axial'
                %conformations = [conformations, {@axial}];
                dbgmsg('Unimplemented normalization: ', varargin{i} ,true);
            case 'spherical'
                conformations = [conformations, {@to_spherical}];
            case 'intostick'
                conformations = [conformations, {@intostick}];
                killdim = [4:(skelldef.length/6) (skelldef.length/6+4):(skelldef.length/3) ];
            case 'intostick2'
                conformations = [conformations, {@intostick2}];
                killdim = [4:(skelldef.length/6) (skelldef.length/6+4):(skelldef.length/3) ];
            otherwise
                dbgmsg('Unimplemented normalization.',varargin{i},true);
        end
    end    
    % execute them for training and validation sets
    if ~isempty(skelldef.bodyparts)
        for i = 1:length(conformations)
            func = conformations{i};
            dbgmsg('Applying normalization: ', varargin{i+lindx-1},true);
            if isequal(func, @mirrorx)||isequal(func,@mirrory)||isequal(func, @mirrorz)
                data_trainmirror = data_train;
                data_valmirror = data_val;
                data_ytrainmirror = data_ytrain;
                data_yvalmirror = data_yval;
            else
                data_trainmirror = [];
                data_valmirror = [];
                data_ytrainmirror = [];
                data_yvalmirror = [];
            end            
            if isequal(func,@normalize)
                    %%% must go through whole dataset!                    
                    allskels = makefatskel(data_train);
                    vectdata_pos = reshape(allskels(1:skelldef.length/6,:,:),1,[]);
                    skelldef.pos_std = std(vectdata_pos);
                    skelldef.pos_mean=mean(vectdata_pos);
                    vectdata_vel = reshape(allskels((skelldef.length/6+1):end,:,:),1,[]);
                    skelldef.vel_std = std(vectdata_vel);
                    skelldef.vel_mean=mean(vectdata_vel);
            end
            for j = 1:size(data_train,2)
                data_train(:,j) = func(data_train(:,j), skelldef);
            end
            for j = 1:size(data_val,2)
                data_val(:,j) = func(data_val(:,j), skelldef);
            end
            data_train = [data_train data_trainmirror];
            data_val = [data_val data_valmirror];
            data_ytrain = [data_ytrain data_ytrainmirror];
            data_yval = [data_yval data_yvalmirror];
        end
    end
    % squeeze them accordingly?
    if ~test
        whattokill = reshape(1:skelldef.length,skelldef.length/3,3);
        realkilldim = whattokill(killdim,:);
        conform_train = data_train(setdiff(1:skelldef.length,realkilldim),:);
        conform_val = data_val(setdiff(1:skelldef.length,realkilldim),:);
        skelldef.elementorder = skelldef.elementorder(setdiff(1:skelldef.length,realkilldim));
        %%% awk
        skelldef.awk.pos = repmat(awk(setdiff(1:skelldef.length/6,killdim)),3,1);
        skelldef.awk.vel = repmat(awk(setdiff(1:skelldef.length/6,killdim)),3,1);
    else
        conform_train = data_train;
        conform_val = data_val;
    end
conformstruc.train.data = conform_train;
conformstruc.val.data = conform_val;        
end
skelldef.realkilldim = realkilldim;
[skelldef.pos, skelldef.vel] = generateidx(skelldef.length, skelldef);
end
function newskel = centerhips(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
if isempty(bod.SpineBase)&&hh==30
    hip = (tdskel(bod.LEFT_HIP,:) + tdskel(bod.RIGHT_HIP,:))/2;
else
    hip = tdskel(bod.SpineBase,:);    
end
hips = [repmat(hip,hh/2,1);zeros(hh/2,3)];
newskel = tdskel - hips;
newskel = makethinskel(newskel);
end
function newskel = highhips(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
if isempty(bod.SpineBase)&&hh==30
    hip = (tdskel(bod.LEFT_HIP,:) + tdskel(bod.RIGHT_HIP,:))/2;
else
    hip = tdskel(bod.SpineBase,:);
    
end
hip(1,2) = 0; 
hips = [repmat(hip,hh/2,1);zeros(hh/2,3)]; 
newskel = tdskel - hips;
newskel = makethinskel(newskel);
end
function newskel = centertorax(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
torax = [repmat(tdskel(bod.TORSO,:),hh/2,1);zeros(hh/2,3)];
newskel = tdskel - torax;
newskel = makethinskel(newskel);
end
function newskel = norotatehips(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
rvec = tdskel(bod.RIGHT_HIP,:)-tdskel(bod.LEFT_HIP,:);
rotmat = vecRotMat(rvec/norm(rvec),[1 0 0 ]);
for i = 1:hh
    tdskel(i,:) = (rotmat*tdskel(i,:)')';
end
newskel = makethinskel(tdskel);
end
function newskel = norotateshoulders(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
rvec = tdskel(bod.LEFT_SHOULDER,:)-tdskel(bod.LEFT_SHOULDER,:);
rotmat = vecRotMat(rvec/norm(rvec),[1 0 0 ]); 
for i = 1:hh
    tdskel(i,:) = (rotmat*tdskel(i,:)')';
end
newskel = makethinskel(tdskel);
end
function newskel = nofeet(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
sizeofnans = size(tdskel([bod.RIGHT_FOOT, bod.LEFT_FOOT],:));
tdskel([bod.RIGHT_FOOT, bod.LEFT_FOOT],:) = NaN(sizeofnans);
newskel = makethinskel(tdskel);
end
function newskel = mirrorx(skel, ~)
[tdskel,~] = makefatskel(skel);
tdskel(:,1) = -tdskel(:,1);
newskel = makethinskel(tdskel);
end
function newskel = mirrory(skel, ~)
[tdskel,~] = makefatskel(skel);
tdskel(:,2) = -tdskel(:,2);
newskel = makethinskel(tdskel);
end
function newskel = mirrorz(skel, ~)
[tdskel,~] = makefatskel(skel);
tdskel(:,3) = -tdskel(:,3);
newskel = makethinskel(tdskel);
end
function newskel = normalize(skel, skelldef)
[tdskel,hh] = makefatskel(skel);
for i = 1:hh/2
    tdskel(i,:) = (tdskel(i,:) - skelldef.pos_mean)/skelldef.pos_std; %- skelldef.pos_mean
end
for i = (hh/2+1):hh
    tdskel(i,:) = (tdskel(i,:) - skelldef.vel_mean)/skelldef.vel_std;%- skelldef.vel_mean
end
newskel = makethinskel(tdskel);
end
function newskel = to_spherical(skel, ~)
[tdskel,~] = makefatskel(skel);
newskel = zeros(size(tdskel));
[newskel(:,1),newskel(:,2),newskel(:,3)] = cart2sph(tdskel(:,1),tdskel(:,2),tdskel(:,3));
newskel = makethinskel(newskel);
end
function newskel = intostick(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
%disp('ok')
UCI = [bod.HEAD bod.NECK bod.LEFT_SHOULDER  bod.RIGHT_SHOULDER bod.LEFT_ELBOW bod.RIGHT_ELBOW bod.LEFT_HAND bod.RIGHT_HAND  ];
uppercentroid = mean(tdskel(UCI ,:));
uppercentroidvel  = mean(tdskel(UCI+hh/2,:));
middlecentroid = tdskel(bod.TORSO,:);
middlecentroidvel = tdskel(bod.TORSO+hh/2,:);
LCI = [bod.LEFT_FOOT bod.RIGHT_FOOT bod.LEFT_KNEE bod.RIGHT_KNEE bod.LEFT_HIP bod.RIGHT_HIP];
lowercentroid =mean(tdskel(LCI,:));
lowercentroidvel =mean(tdskel(LCI+hh/2,:));
zeroskel = zeros(size(tdskel));
zeroskel(1:3,:) = [uppercentroid;middlecentroid;lowercentroid];
zeroskel((hh/2+1):(hh/2+3),:) = [uppercentroidvel;middlecentroidvel;lowercentroidvel];
newskel = makethinskel(zeroskel);
end
function newskel = intostick2(skel, skelldef)
bod = skelldef.bodyparts;
[tdskel,hh] = makefatskel(skel);
UCI = [bod.HEAD bod.NECK bod.LEFT_SHOULDER  bod.RIGHT_SHOULDER bod.LEFT_ELBOW bod.RIGHT_ELBOW  ];
uppercentroid = mean(tdskel(UCI ,:));
uppercentroidvel  = mean(tdskel(UCI+hh/2,:));
middlecentroid = tdskel(bod.TORSO,:);
middlecentroidvel = tdskel(bod.TORSO+hh/2,:);
LCI = [ bod.LEFT_KNEE bod.RIGHT_KNEE bod.LEFT_HIP bod.RIGHT_HIP];
lowercentroid =mean(tdskel(LCI,:));
lowercentroidvel =mean(tdskel(LCI+hh/2,:));
zeroskel = zeros(size(tdskel));
zeroskel(1:3,:) = [uppercentroid;middlecentroid;lowercentroid];
zeroskel((hh/2+1):(hh/2+3),:) = [uppercentroidvel;middlecentroidvel;lowercentroidvel];
newskel = makethinskel(zeroskel);
end
function bodyparts = genbodyparts(lenlen)
bodyparts = struct();
switch lenlen
    case 150
        bodyparts.SpineBase = 1;
        bodyparts.SpineMid = 2;
        bodyparts.Neck = 3;
        bodyparts.Head = 4;
        bodyparts.ShoulderLeft = 5;
        bodyparts.ElbowLeft = 6;
        bodyparts.WristLeft = 7;
        bodyparts.HandLeft = 8;
        bodyparts.ShoulderRight = 9;
        bodyparts.ElbowRight = 10;
        bodyparts.WristRight = 11;
        bodyparts.HandRight = 12;
        bodyparts.HipLeft = 13;
        bodyparts.KneeLeft = 14;
        bodyparts.AnkleLeft = 15;
        bodyparts.FootLeft = 16;
        bodyparts.HipRight = 17;
        bodyparts.KneeRight = 18;
        bodyparts.AnkleRight = 19;
        bodyparts.FootRight = 20;
        bodyparts.SpineShoulder = 21;
        bodyparts.HandTipLeft = 22;
        bodyparts.ThumbLeft = 23;
        bodyparts.HandTipRight = 24;
        bodyparts.ThumbRight = 25;
        %%% synonyms
        bodyparts.NECK = bodyparts.Neck;
        bodyparts.RIGHT_HIP = bodyparts.HipRight;
        bodyparts.LEFT_HIP = bodyparts.HipLeft;        
        bodyparts.LEFT_SHOULDER = bodyparts.ShoulderLeft;
        bodyparts.RIGHT_SHOULDER = bodyparts.ShoulderRight;        
        bodyparts.LEFT_ELBOW = bodyparts.WristRight;
        bodyparts.RIGHT_ELBOW = bodyparts.WristLeft;
        bodyparts.LEFT_KNEE =  bodyparts.KneeLeft;
        bodyparts.RIGHT_KNEE = bodyparts.KneeRight;        
        bodyparts.RIGHT_FOOT =  [bodyparts.AnkleRight,	 bodyparts.FootRight];
        bodyparts.LEFT_FOOT =  [bodyparts.AnkleLeft,	 bodyparts.FootLeft];
        bodyparts.HEAD	=	 bodyparts.Head;
        bodyparts.TORSO = bodyparts.SpineShoulder;
        bodyparts.RIGHT_HAND = [bodyparts.HandTipRight bodyparts.ThumbRight];
        bodyparts.LEFT_HAND = [bodyparts.HandTipLeft bodyparts.ThumbLeft];        
    case 120
        bodyparts.SpineBase = 1;
        bodyparts.spine = 2;
        bodyparts.shoulder_center = 3;
        bodyparts.head = 4;
        bodyparts.shoulder_left = 5;
        bodyparts.elbow_left = 6;
        bodyparts.wrist_left = 7;
        bodyparts.hand_left = 8;
        bodyparts.shoulder_right = 9;
        bodyparts.elbow_right = 10;
        bodyparts.wrist_right = 11;
        bodyparts.hand_right = 12;
        bodyparts.hip_left = 13;
        bodyparts.knee_left = 14;
        bodyparts.ankle_left = 15;
        bodyparts.foot_left = 16;
        bodyparts.hip_right = 17;
        bodyparts.knee_right = 18;
        bodyparts.ankle_right = 19;
        bodyparts.foot_right = 20;
        %%% synonyms
        bodyparts.RIGHT_HIP = bodyparts.hip_right;
        bodyparts.LEFT_HIP = bodyparts.hip_left;        
        bodyparts.LEFT_SHOULDER = bodyparts.shoulder_left;
        bodyparts.RIGHT_SHOULDER = bodyparts.shoulder_right;        
        bodyparts.RIGHT_FOOT =  [bodyparts.ankle_right,	 bodyparts.foot_right];
        bodyparts.LEFT_FOOT =  [bodyparts.ankle_left,	 bodyparts.foot_left];
        bodyparts.HEAD	=	 bodyparts.head;
        bodyparts.TORSO = bodyparts.shoulder_center;
        bodyparts.LEFT_HAND = [bodyparts.wrist_left, bodyparts.hand_left];
        bodyparts.RIGHT_HAND = [bodyparts.wrist_right, bodyparts.hand_right];        
    case 90
        bodyparts.HEAD = 1;
        bodyparts.NECK = 2;
        bodyparts.TORSO = 3;
        bodyparts.LEFT_SHOULDER = 4;
        bodyparts.LEFT_ELBOW = 5;
        bodyparts.RIGHT_SHOULDER = 6;
        bodyparts.RIGHT_ELBOW = 7;
        bodyparts.LEFT_HIP = 8;
        bodyparts.LEFT_KNEE = 9;
        bodyparts.RIGHT_HIP = 10;
        bodyparts.RIGHT_KNEE = 11;
        bodyparts.LEFT_HAND = 12;
        bodyparts.RIGHT_HAND = 13;
        bodyparts.LEFT_FOOT = 14;
        bodyparts.RIGHT_FOOT = 15;
        %%%
        bodyparts.SpineBase = [];        
    otherwise
        dbgmsg('Unknown size of skeleton.')
        return
end
end